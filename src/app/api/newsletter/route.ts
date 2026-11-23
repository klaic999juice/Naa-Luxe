import { createClient } from '@/lib/supabase/server';
import { NextResponse } from 'next/server';

export async function POST(req: Request) {
  try {
    const { email } = await req.json();
    if (typeof email !== 'string' || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return NextResponse.json({ error: 'Enter a valid email address.' }, { status: 400 });
    const db = await createClient();
    const { error } = await db.from('newsletter_subscribers').upsert({ email: email.trim().toLowerCase() }, { onConflict: 'email' });
    if (error) return NextResponse.json({ error: 'Unable to subscribe right now. Please try again.' }, { status: 400 });
    return NextResponse.json({ ok: true });
  } catch {
    return NextResponse.json({ error: 'Unable to subscribe right now. Please try again.' }, { status: 400 });
  }
}
