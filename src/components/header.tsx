'use client';

import Link from 'next/link';
import { useState } from 'react';
import { Search, ShoppingBag, UserRound, Menu, X } from 'lucide-react';

export function Header() {
  const [menuOpen, setMenuOpen] = useState(false);
  return <header className="site-header">
    <button className="mobile-menu" aria-label={menuOpen ? 'Close menu' : 'Open menu'} aria-expanded={menuOpen} onClick={() => setMenuOpen(!menuOpen)}>{menuOpen ? <X size={19}/> : <Menu size={19}/>}</button>
    <nav className={`nav-links${menuOpen ? ' nav-open' : ''}`} onClick={() => setMenuOpen(false)}><Link href="/shop">Shop</Link><Link href="/shop?category=New%20In">New In</Link><Link href="/community">Community</Link><Link href="/about">Our Story</Link></nav>
    <Link href="/" className="brand">NAA LUXE<small>CONSIDERED LUXURY</small></Link>
    <div className="header-actions"><Link href="/shop" aria-label="Search"><Search size={17}/></Link><Link href="/account" aria-label="Account"><UserRound size={17}/></Link><Link className="cart-link" href="/cart" aria-label="Shopping bag"><ShoppingBag size={17}/></Link></div>
  </header>;
}
