import Link from 'next/link';

export default async function Success({searchParams}:{searchParams:Promise<{reference?:string}>}){const {reference}=await searchParams;return <main className="page-wrap"><div className="empty"><span className="eyebrow">Payment confirmed</span><h1 className="page-title">Thank you for your order.</h1><p>Your payment was verified securely. Order reference: <strong>{reference}</strong></p><p className="muted">You can follow your order progress from your account.</p><Link className="button" href="/account">View my account</Link></div></main>}
