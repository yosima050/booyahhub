// supabase/functions/send-push/index.ts
// Edge Function: Mengirim push notification ke perangkat pengguna melalui FCM.
// Deploy: supabase functions deploy send-push --no-verify-jwt

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { SignJWT, importPKCS8 } from 'https://esm.sh/jose@5.2.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// OAuth2 scope untuk Firebase Cloud Messaging
const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';

/**
 * Mendapatkan OAuth2 Access Token untuk FCM menggunakan Google Service Account
 */
async function getFcmAccessToken(serviceAccountJson: string): Promise<{ token: string; projectId: string }> {
  const account = JSON.parse(serviceAccountJson);
  const jwtHeader = { alg: 'RS256', typ: 'JWT' };
  const now = Math.floor(Date.now() / 1000);

  const jwtPayload = {
    iss: account.client_email,
    scope: FCM_SCOPE,
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600, // Valid selama 1 jam
    iat: now,
  };

  // Import private key RSA PKCS8
  const privateKey = await importPKCS8(account.private_key, 'RS256');

  // Buat dan tanda tangani JWT
  const jwt = await new SignJWT(jwtPayload)
    .setProtectedHeader(jwtHeader)
    .sign(privateKey);

  // Ambil Access Token dari Google OAuth2
  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  if (!tokenResponse.ok) {
    const errText = await tokenResponse.text();
    throw new Error(`Gagal mendapatkan OAuth2 token: ${errText}`);
  }

  const tokenData = await tokenResponse.json();
  return {
    token: tokenData.access_token,
    projectId: account.project_id,
  };
}

Deno.serve(async (req: Request) => {
  // Tangani preflight request
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseServiceRole = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    const webhookSecret = Deno.env.get('WEBHOOK_SECRET') ?? 'BOOYAH_SECRET_12345';

    // Verifikasi Token Webhook untuk Keamanan
    const incomingSecret = req.headers.get('x-webhook-secret');
    if (incomingSecret !== webhookSecret) {
      console.warn('Unauthorized attempt to trigger send-push webhook.');
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRole);

    // Ambil payload record notifikasi baru
    const payload = await req.json();
    const { record } = payload;
    
    if (!record) {
      return new Response(JSON.stringify({ error: 'Record payload missing' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { user_id, title, message, type, data: extraData } = record;

    console.log(`Memproses push notification untuk user_id: ${user_id}, tipe: ${type}`);

    // 1. Ambil token perangkat yang aktif untuk user ini
    const { data: deviceTokens, error: tokensError } = await supabaseAdmin
      .from('device_tokens')
      .select('id, token, platform')
      .eq('user_id', user_id)
      .eq('is_active', true);

    if (tokensError) {
      console.error('Error fetching device tokens:', tokensError.message);
      return new Response(JSON.stringify({ error: tokensError.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (!deviceTokens || deviceTokens.length === 0) {
      console.log(`Tidak ada device token aktif untuk user_id: ${user_id}. Selesai.`);
      return new Response(JSON.stringify({ success: true, message: 'No active device tokens found.' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    console.log(`Ditemukan ${deviceTokens.length} device token aktif.`);

    // 2. Baca kredensial Firebase Service Account dari Environment
    const firebaseServiceAccount = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');

    if (!firebaseServiceAccount) {
      console.warn('WARNING: FIREBASE_SERVICE_ACCOUNT is not configured. Mocking push notifications.');
      return new Response(
        JSON.stringify({
          success: true,
          message: 'FIREBASE_SERVICE_ACCOUNT is not configured. Webhook handled successfully.',
          mocked: true,
          recipient_count: deviceTokens.length,
          payload: { title, message, type }
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 3. Autentikasi dengan Firebase
    let accessToken: string;
    let firebaseProjectId: string;
    try {
      const authResult = await getFcmAccessToken(firebaseServiceAccount);
      accessToken = authResult.token;
      firebaseProjectId = authResult.projectId;
    } catch (authErr) {
      console.error('Error authenticating with Firebase:', authErr);
      return new Response(JSON.stringify({ error: 'Firebase authentication failed' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 4. Kirim notifikasi ke setiap token perangkat
    const sendPromises = deviceTokens.map(async (device) => {
      const fcmUrl = `https://fcm.googleapis.com/v1/projects/${firebaseProjectId}/messages:send`;
      
      const fcmPayload = {
        message: {
          token: device.token,
          notification: {
            title: title,
            body: message,
          },
          data: {
            type: type || 'notification',
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            ...(extraData ? { data: JSON.stringify(extraData) } : {}),
          },
          android: {
            priority: 'high',
            notification: {
              sound: 'default',
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
                badge: 1,
              },
            },
          },
        },
      };

      try {
        const res = await fetch(fcmUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${accessToken}`,
          },
          body: JSON.stringify(fcmPayload),
        });

        if (!res.ok) {
          const resBody = await res.json();
          const errorCode = resBody.error?.status;
          
          console.error(`Gagal mengirim ke token ${device.token}:`, resBody.error);

          // Jika token sudah tidak valid / tidak terdaftar lagi di FCM, nonaktifkan di DB
          if (errorCode === 'UNREGISTERED' || errorCode === 'INVALID_ARGUMENT') {
            console.log(`Menonaktifkan token tidak valid di database: ${device.token}`);
            await supabaseAdmin
              .from('device_tokens')
              .update({ is_active: false, updated_at: new Date().toISOString() })
              .eq('id', device.id);
          }
          return { tokenId: device.id, success: false, error: resBody.error };
        }

        const resData = await res.json();
        console.log(`Sukses mengirim ke token ${device.token}: ${resData.name}`);
        
        // Update waktu terakhir digunakan
        await supabaseAdmin
          .from('device_tokens')
          .update({ last_used_at: new Date().toISOString() })
          .eq('id', device.id);

        return { tokenId: device.id, success: true };
      } catch (err) {
        console.error(`Exception saat mengirim ke token ${device.token}:`, err);
        return { tokenId: device.id, success: false, error: String(err) };
      }
    });

    const results = await Promise.all(sendPromises);

    return new Response(JSON.stringify({ success: true, results }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('Global handler error in send-push:', err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
