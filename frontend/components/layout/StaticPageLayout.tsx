export default function StaticPageLayout({ 
  title, 
  description, 
  lastUpdated,
  children 
}: { 
  title: string
  description?: string
  lastUpdated?: string
  children: React.ReactNode 
}) {
  return (
    <div className="bg-white dark:bg-gray-900">
      <div className="mx-auto max-w-4xl px-6 py-16 sm:py-24 lg:px-8">
        <div className="mx-auto max-w-3xl lg:mx-0">
          <h1 className="text-4xl font-bold tracking-tight text-gray-900 dark:text-white sm:text-5xl">
            {title}
          </h1>
          {description && (
            <p className="mt-6 text-xl leading-8 text-gray-600 dark:text-gray-300">
              {description}
            </p>
          )}
          {lastUpdated && (
            <p className="mt-4 text-sm text-gray-500 dark:text-gray-400">
              Last updated: {lastUpdated}
            </p>
          )}
        </div>
        <div className="mx-auto mt-16 max-w-3xl">
          <div className="prose prose-lg prose-gray dark:prose-invert max-w-none">
            {children}
          </div>
        </div>
      </div>
    </div>
  )
}