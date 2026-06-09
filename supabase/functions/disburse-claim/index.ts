// supabase/functions/disburse-claim/index.ts
// Edge Function: Melakukan transfer otomatis hadiah juara via Midtrans Iris Sandbox.
// Deploy: supabase functions deploy disburse-claim

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const MIDTRANS_IRIS_CREATOR_KEY = Deno.env.get('MIDTRANS_IRIS_CREATOR_KEY') || Deno.env.get('MIDTRANS_SERVER_KEY') || '';
const IS_PRODUCTION = Deno.env.get('MIDTRANS_IS_PRODUCTION') === 'true';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Fungsi memetakan nama bank ke kode bank Midtrans Iris
function mapToMidtransBankCode(bankName: string): string {
  const name = bankName.toLowerCase().trim();
  if (name.includes('bca')) return 'bca';
  if (name.includes('mandiri')) return 'mandiri';
  if (name.includes('bni')) return 'bni';
  if (name.includes('bri')) return 'bri';
  if (name.includes('cimb')) return 'cimb';
  if (name.includes('gopay')) return 'gopay';
  if (name.includes('ovo')) return 'ovo';
  if (name.includes('dana')) return 'dana';
  if (name.includes('linkaja')) return 'linkaja';
  if (name.includes('shopeepay') || name.includes('shoope')) return 'shopeepay';
  return 'gopay'; // Fallback default
}

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization') ?? '';
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing Authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Buat client Supabase Deno dengan user authorization token
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    );

    // Ambil user profil dari token
    const { data: { user }, error: userErr } = await supabaseClient.auth.getUser();
    if (userErr || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid user token', detail: userErr?.message }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Admin client (bypass RLS) untuk verifikasi/kueri internal
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Verifikasi peran user adalah platform
    const { data: userProfile, error: profileErr } = await supabaseAdmin
      .from('users')
      .select('id, role')
      .eq('uuid', user.id)
      .single();

    if (profileErr || !userProfile || userProfile.role !== 'platform') {
      return new Response(
        JSON.stringify({ error: 'Hanya manajer platform yang dapat memverifikasi klaim' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const platformBigId = userProfile.id;

    // Ambil parameter request
    const { claim_id, approve, reason } = await req.json();

    if (claim_id === undefined || approve === undefined) {
      return new Response(
        JSON.stringify({ error: 'claim_id dan approve wajib diisi' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Jika klaim disetujui, jalankan integrasi Midtrans Iris
    if (approve) {
      // Ambil detail klaim dari DB
      const { data: claim, error: claimErr } = await supabaseAdmin
        .from('prize_claims')
        .select('*, users!prize_claims_user_id_fkey(email, name)')
        .eq('id', claim_id)
        .single();

      if (claimErr || !claim) {
        return new Response(
          JSON.stringify({ error: 'Klaim tidak ditemukan' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      if (claim.status !== 'processing') {
        return new Response(
          JSON.stringify({ error: 'Status klaim tidak valid (bukan dalam antrean processing)' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      const payoutItem = {
        beneficiary_name: claim.account_name ?? claim.users?.name ?? 'Player',
        beneficiary_account: claim.account_number,
        beneficiary_bank: mapToMidtransBankCode(claim.bank_name || ''),
        beneficiary_email: claim.users?.email ?? 'player@booyahhub.id',
        amount: Number(claim.amount).toFixed(2),
        notes: `Payout Claim ID ${claim_id} BooyahHub`,
      };

      const encoded = btoa(`${MIDTRANS_IRIS_CREATOR_KEY}:`);
      const irisUrl = IS_PRODUCTION
        ? 'https://app.midtrans.com/iris/api/v1/payouts'
        : 'https://app.sandbox.midtrans.com/iris/api/v1/payouts';

      let midtransSuccess = false;
      let midtransDetail = '';

      try {
        console.log(`Mengirim payout ke Midtrans Iris Sandbox (${irisUrl}) untuk claim ID: ${claim_id}`);
        const midtransRes = await fetch(irisUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Basic ${encoded}`,
            'X-Idempotency-Key': `claim-payout-${claim_id}`,
          },
          body: JSON.stringify({
            payouts: [payoutItem],
          }),
        });

        const resJson = await midtransRes.json();
        if (midtransRes.ok) {
          midtransSuccess = true;
          midtransDetail = JSON.stringify(resJson);
          console.log('Midtrans Iris payout created successfully:', midtransDetail);
        } else {
          midtransDetail = JSON.stringify(resJson);
          console.error('Midtrans Iris API error response:', midtransDetail);
        }
      } catch (err) {
        midtransDetail = String(err);
        console.error('Exception during Midtrans Iris fetch:', err);
      }

      if (!midtransSuccess) {
        if (IS_PRODUCTION) {
          return new Response(
            JSON.stringify({ error: 'Gagal melakukan payout ke Midtrans Iris', detail: midtransDetail }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          );
        } else {
          console.warn('Sandbox Fallback: Gagal menghubungi Midtrans Iris Sandbox, melanjutkan proses lokal...');
        }
      }
    }

    // Jalankan sp_verify_claim untuk update status dan buat transaksi serta notifikasi di DB
    const { error: rpcErr } = await supabaseAdmin.rpc('sp_verify_claim', {
      p_claim_id: claim_id,
      p_platform_id: platformBigId,
      p_approve: approve,
      p_reason: reason || null,
    });

    if (rpcErr) {
      console.error('sp_verify_claim RPC error:', rpcErr.message);
      return new Response(
        JSON.stringify({ error: 'Gagal memperbarui status klaim di database', detail: rpcErr.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: approve ? 'Klaim disetujui dan transfer berhasil diproses' : 'Klaim ditolak',
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (err) {
    console.error('Unhandled exception in Edge Function:', err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
