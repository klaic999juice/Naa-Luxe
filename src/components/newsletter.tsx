'use client';

import { FormEvent, useState } from 'react';

export function Newsletter() {
  const [message, setMessage] = useState('');
  const [busy, setBusy] = useState(false);
  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setMessage('');
    const form = event.currentTarget;
    try {
      const response = await fetch('/api/newsletter', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: new FormData(form).get('email') }) });
      const result = await response.json();
      if (!response.ok) throw new Error(result.error || 'Could not subscribe. Please try again.');
      setMessage('Thank you for joining our inner circle.');
      form.reset();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Could not subscribe. Please try again.');
    } finally {
      setBusy(false);
    }
  }
  return <section className="newsletter"><span className="eyebrow">A note from Naa Luxe</span><h2>Join our inner circle</h2><p>New arrivals, thoughtful stories and a little something for your next order.</p><form onSubmit={submit}><input name="email" type="email" required placeholder="Your email address" aria-label="Your email address"/><button type="submit" disabled={busy}>{busy ? 'Joining…' : 'Subscribe'}</button></form>{message && <p role="status">{message}</p>}</section>;
}
