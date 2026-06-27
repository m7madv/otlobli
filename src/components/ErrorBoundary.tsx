import { Component, type ErrorInfo, type ReactNode } from 'react'

type Props = { children: ReactNode }
type State = { hasError: boolean }

// يلتقط أي خطأ بالعرض (render) فيمنع انهيار شجرة React كاملةً وظهور شاشة
// سوداء/فارغة، ويعرض بدلها شاشة استرداد بسيطة فيها زر إعادة تحميل.
// التنسيق inline عمداً حتى يشتغل حتى لو كان الخطأ متعلّقاً بالأنماط نفسها.
export class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false }

  static getDerivedStateFromError(): State {
    return { hasError: true }
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    // تسجيل غير حيوي للتشخيص؛ لا يقطع تجربة المستخدم.
    console.error('otlobli ErrorBoundary caught:', error, info.componentStack)
  }

  private handleReload = () => {
    // إعادة تحميل كاملة تعيد بناء التطبيق من جديد بحالة نظيفة.
    window.location.reload()
  }

  render() {
    if (!this.state.hasError) return this.props.children

    return (
      <div
        dir="rtl"
        style={{
          minHeight: '100vh',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 18,
          padding: 24,
          textAlign: 'center',
          background: '#f7f9fb',
          color: '#1a1c1a',
          fontFamily: "'Cairo', system-ui, sans-serif",
        }}
      >
        <div
          style={{
            width: 64,
            height: 64,
            borderRadius: '50%',
            background: '#e7f7ef',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: 32,
          }}
        >
          🔄
        </div>
        <h1 style={{ fontSize: '1.2rem', margin: 0, fontWeight: 800 }}>صار خطأ بسيط</h1>
        <p style={{ fontSize: '0.95rem', margin: 0, maxWidth: 320, lineHeight: 1.6, color: '#3d4a42' }}>
          واجه التطبيق مشكلة مؤقتة. اضغط الزر لإعادة التحميل ومتابعة استخدام otlobli — بياناتك وسلتك محفوظة.
        </p>
        <button
          onClick={this.handleReload}
          style={{
            border: 'none',
            borderRadius: 12,
            padding: '14px 28px',
            background: '#006948',
            color: '#fff',
            fontWeight: 700,
            fontSize: '1rem',
            cursor: 'pointer',
            fontFamily: 'inherit',
          }}
        >
          إعادة التحميل
        </button>
      </div>
    )
  }
}
