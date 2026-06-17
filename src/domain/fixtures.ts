import type { Address, Order, PriceLine, Product } from './types'

export const orderStatuses = [
  'بانتظار الدفع',
  'تم الدفع',
  'قيد الشراء',
  'تم الشراء',
  'في الطريق إلى الأردن',
  'وصل الأردن',
  'قيد الشحن إلى سوريا',
  'مع القدموس',
  'جاهز للاستلام',
  'تم التسليم',
]

export const product: Product = {
  id: 'SHEIN-DRS-204',
  title: 'فستان بوهيمي مزين بالزهور',
  source: 'SHEIN Jordan',
  link: 'https://jo.shein.com/example-product-p-12345.html',
  priceUsd: 25,
  priceSyp: 325000,
  weight: '0.62 كغ',
  deliveryWindow: '10 إلى 15 يوم عمل',
  images: [
    'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?auto=format&fit=crop&w=900&q=84',
    'https://images.unsplash.com/photo-1496747611176-843222e1e57c?auto=format&fit=crop&w=900&q=84',
    'https://images.unsplash.com/photo-1539008835657-9e8e9680c956?auto=format&fit=crop&w=900&q=84',
  ],
  colors: [
    {
      name: 'نقشة زهور ربيعية',
      image: 'https://images.unsplash.com/photo-1496747611176-843222e1e57c?auto=format&fit=crop&w=200&q=72',
    },
    {
      name: 'أزرق هادئ',
      image: 'https://images.unsplash.com/photo-1485968579580-b6d095142e6e?auto=format&fit=crop&w=200&q=72',
    },
    {
      name: 'كريمي',
      image: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=200&q=72',
    },
  ],
  sizes: ['S', 'M', 'L', 'XL'],
}

export const allowedProducts = ['ملابس', 'أحذية', 'شنط', 'إكسسوارات']
export const blockedProducts = ['إلكترونيات', 'عطور', 'بطاريات', 'أدوية', 'مكملات']

// تكلفة شحن ثابتة واحدة تظهر كسطر واحد في تفاصيل التكلفة (تشمل شحن SHEIN
// للأردن، شحن الأردن لسوريا، توصيل القدموس، ورسوم المنصة مجمّعة).
export const FIXED_SHIPPING_SYP = 90000

export const shippingFees: PriceLine[] = [
  { label: 'تكلفة الشحن', value: FIXED_SHIPPING_SYP },
]

export const paymentSettings = {
  provider: 'شام كاش B2B',
  receiverName: 'شركة otlobli للتجارة الإلكترونية',
  receiverAccount: '09xx xxx xxx',
  rule: 'المطابقة تتم بالمبلغ الدقيق فقط. لا نحتاج رقم الطلب في الملاحظة.',
}

export const initialAddresses: Address[] = []

export const initialOrders: Order[] = []
