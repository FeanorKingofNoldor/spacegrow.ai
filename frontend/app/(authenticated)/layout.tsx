import { Sidebar } from '@/components/navigation/Sidebar'
import { AuthenticatedHeader } from '@/components/navigation/AuthenticatedHeader'

export default function AuthenticatedLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="flex h-screen bg-gray-100">
      <Sidebar />
      <div className="flex-1 flex flex-col overflow-hidden">
        <AuthenticatedHeader toggleSidebar={() => {}} />
        <main className="flex-1 overflow-auto p-4">{children}</main>
      </div>
    </div>
  )
}