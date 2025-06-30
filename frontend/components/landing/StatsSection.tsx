// components/landing/StatsSection.tsx
'use client';

const stats = [
  { label: 'Active Devices', value: '10,000+' },
  { label: 'Data Points Collected', value: '50M+' },
  { label: 'Uptime Guarantee', value: '99.9%' },
  { label: 'Countries Served', value: '25+' },
];

export function StatsSection() {
  return (
    <section className="bg-gray-900 py-24 sm:py-32">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <div className="mx-auto max-w-2xl lg:mx-0">
          <h2 className="text-pretty text-4xl font-semibold tracking-tight text-white sm:text-5xl">
            Trusted by growers worldwide
          </h2>
          <p className="mt-6 text-base/7 text-gray-300">
            Join thousands of successful growers who trust XSpaceGrow to monitor and optimize their environments.
          </p>
        </div>
        <div className="mx-auto mt-16 flex max-w-2xl flex-col gap-8 lg:mx-0 lg:mt-20 lg:max-w-none lg:flex-row lg:items-end">
          <div className="flex flex-col-reverse justify-between gap-x-16 gap-y-8 rounded-2xl bg-gray-800/50 p-8 sm:w-3/5 sm:max-w-md sm:flex-row-reverse sm:items-end lg:w-72 lg:max-w-none lg:flex-none lg:flex-col lg:items-start">
            <p className="flex-none text-3xl font-bold tracking-tight text-white">250,000</p>
            <div className="sm:w-80 sm:shrink lg:w-auto lg:flex-none">
              <p className="text-lg font-semibold tracking-tight text-white">Hours of continuous monitoring</p>
              <p className="mt-2 text-base/7 text-gray-400">
                Our devices work around the clock to ensure your environment stays optimal.
              </p>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4 sm:gap-6 lg:gap-8 lg:flex-auto">
            {stats.map((stat) => (
              <div
                key={stat.label}
                className="rounded-2xl bg-gray-800/50 p-6 hover:bg-gray-800/70 transition-colors"
              >
                <p className="text-sm/6 font-medium text-gray-400">{stat.label}</p>
                <p className="mt-2 text-3xl font-bold tracking-tight text-white">{stat.value}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}