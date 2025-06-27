import { Header } from '@/components/navigation/Header'
import { Footer } from '@/components/navigation/Footer'

export default function PublicLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <>
      <Header />
      <main>{children}</main>
      <Footer />
    </>
  )
}