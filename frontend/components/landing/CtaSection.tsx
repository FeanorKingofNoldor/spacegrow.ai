// components/landing/CtaSection.tsx
'use client';

export function CtaSection() {
  return (
    <section className="bg-gray-950">
      <div className="px-6 py-24 sm:px-6 sm:py-32 lg:px-8">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-balance text-4xl font-semibold tracking-tight text-white sm:text-5xl">
            Ready to grow smarter?
          </h2>
          <p className="mx-auto mt-6 max-w-xl text-lg/8 text-gray-300">
            Start monitoring your environment with precision sensors and intelligent automation.
            Professional results, hobbyist friendly.
          </p>
          <div className="mt-10 flex items-center justify-center gap-x-6">
            <a
              href="/shop"
              className="rounded-md bg-green-600 px-6 py-3 text-sm font-semibold text-white shadow-sm hover:bg-green-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-green-500 transition-colors"
            >
              Shop Now
            </a>
            <a
              href="/pricing"
              className="rounded-md bg-white/10 px-6 py-3 text-sm font-semibold text-white ring-1 ring-inset ring-white/20 hover:bg-white/20 transition-colors"
            >
              View Pricing
            </a>
          </div>
        </div>
      </div>
    </section>
  );
}