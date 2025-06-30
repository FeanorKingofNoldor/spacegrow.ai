export default function StaticPageTemplate({ 
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
    <div className="bg-space-primary min-h-screen">
      <div className="mx-auto max-w-4xl px-6 py-16 sm:py-24 lg:px-8">
        <div className="mx-auto max-w-3xl lg:mx-0">
          <h1 className="text-4xl font-bold tracking-tight text-cosmic-text sm:text-5xl text-gradient-cosmic">
            {title}
          </h1>
          {description && (
            <p className="mt-6 text-xl leading-8 text-cosmic-text-muted">
              {description}
            </p>
          )}
          {lastUpdated && (
            <p className="mt-4 text-sm text-cosmic-text-light">
              Last updated: {lastUpdated}
            </p>
          )}
        </div>
        <div className="mx-auto mt-16 max-w-3xl">
          <div className="bg-space-glass rounded-2xl p-8 animate-nebula-glow">
            <div className="prose prose-lg prose-gray dark:prose-invert max-w-none [&>*]:text-cosmic-text [&>h2]:text-cosmic-text [&>h3]:text-cosmic-text [&>p]:text-cosmic-text-muted [&>li]:text-cosmic-text-muted">
              {children}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}