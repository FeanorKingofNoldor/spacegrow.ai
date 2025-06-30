// components/landing/HeroSection.tsx
'use client';

export function HeroSection() {
  return (
    <div className="bg-space-primary min-h-screen">
      <div className="relative isolate overflow-hidden">
        <div
          aria-hidden="true"
          className="absolute inset-x-0 -top-40 -z-10 transform-gpu overflow-hidden blur-3xl sm:-top-80"
        >
          <div
            style={{
              clipPath:
                'polygon(74.1% 44.1%, 100% 61.6%, 97.5% 26.9%, 85.5% 0.1%, 80.7% 2%, 72.5% 32.5%, 60.2% 62.4%, 52.4% 68.1%, 47.5% 58.3%, 45.2% 34.5%, 27.5% 76.7%, 0.1% 64.9%, 17.9% 100%, 27.6% 76.8%, 76.1% 97.7%, 74.1% 44.1%)',
            }}
            className="relative left-[calc(50%-11rem)] aspect-[1155/678] w-[36.125rem] -translate-x-1/2 rotate-[30deg] bg-gradient-cosmic opacity-40 sm:left-[calc(50%-30rem)] sm:w-[72.1875rem] animate-nebula-glow"
          />
        </div>
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl py-32 sm:py-48 lg:py-56">
            <div className="hidden sm:mb-8 sm:flex sm:justify-center">
              <div className="relative rounded-full px-3 py-1 text-sm/6 text-cosmic-text-muted ring-1 ring-space-border hover:bg-space-glass transition-all duration-200">
                Revolutionary IoT growing technology.{' '}
                <a href="/about" className="font-semibold text-stellar-accent hover:text-cosmic-text transition-colors">
                  <span aria-hidden="true" className="absolute inset-0" />
                  Learn more <span aria-hidden="true">&rarr;</span>
                </a>
              </div>
            </div>
            <div className="text-center">
              <h1 className="text-balance text-5xl font-semibold tracking-tight text-gradient-cosmic sm:text-7xl">
                Smart IoT devices for intelligent growing
              </h1>
              <p className="mt-8 text-pretty text-lg font-medium text-cosmic-text-muted sm:text-xl/8">
                Monitor, control, and optimize your growing environment with precision sensors, automated controls, and real-time data insights.
              </p>
              <div className="mt-10 flex items-center justify-center gap-x-6">
                <a
                  href="/shop"
                  className="group rounded-lg bg-gradient-cosmic px-4 py-3 text-sm font-semibold text-white shadow-lg hover:scale-105 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-stellar-accent transition-all duration-200 animate-nebula-glow"
                >
                  Shop Devices
                  <span className="inline-block transition-transform group-hover:translate-x-1 ml-1">→</span>
                </a>
                <a href="/about" className="text-sm/6 font-semibold text-cosmic-text hover:text-stellar-accent transition-colors">
                  Learn more <span aria-hidden="true">→</span>
                </a>
              </div>
            </div>
          </div>
        </div>
        <div
          aria-hidden="true"
          className="absolute inset-x-0 top-[calc(100%-13rem)] -z-10 transform-gpu overflow-hidden blur-3xl sm:top-[calc(100%-30rem)]"
        >
          <div
            style={{
              clipPath:
                'polygon(74.1% 44.1%, 100% 61.6%, 97.5% 26.9%, 85.5% 0.1%, 80.7% 2%, 72.5% 32.5%, 60.2% 62.4%, 52.4% 68.1%, 47.5% 58.3%, 45.2% 34.5%, 27.5% 76.7%, 0.1% 64.9%, 17.9% 100%, 27.6% 76.8%, 76.1% 97.7%, 74.1% 44.1%)',
              }}
            className="relative left-[calc(50%+3rem)] aspect-[1155/678] w-[36.125rem] -translate-x-1/2 bg-gradient-nebula opacity-30 sm:left-[calc(50%+36rem)] sm:w-[72.1875rem] animate-slow-float-reverse"
          />
        </div>
      </div>
    </div>
  );
}