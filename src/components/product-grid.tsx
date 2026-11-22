'use client';
import Link from 'next/link';
export type Product={id:string;name:string;slug:string;price:number;discount_price:number|null;image_url:string|null;category:string|null};
export function ProductGrid({products}:{products:Product[]}){return <div className="product-grid">{products.map(p=><Link className="product-card" key={p.id} href={`/products/${p.slug}`}><div className="product-image">{p.discount_price&&<span className="badge">Special price</span>}<img src={p.image_url||'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=800&q=80'} alt={p.name}/></div><h3 className="product-title">{p.name}</h3><div className="product-meta"><span>{p.category||'Naa Luxe'}</span><span>GH₵ {Number(p.discount_price||p.price).toFixed(2)}</span></div></Link>)}</div>}
