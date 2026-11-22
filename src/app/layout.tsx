import type { Metadata } from 'next';
import './globals.css';
import { Header } from '@/components/header';
import { Footer } from '@/components/footer';
export const metadata: Metadata = { title: { default: 'Naa Luxe — Considered luxury', template: '%s | Naa Luxe' }, description: 'Discover considered luxury, modern Ghanaian style and exceptional everyday pieces at Naa Luxe.', metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000') };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) { return <html lang="en"><body><div className="announcement">Complimentary delivery on orders over GH₵1,000 <span>✦</span> Accra, Ghana</div><Header />{children}<Footer /></body></html>; }
