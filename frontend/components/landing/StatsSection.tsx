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
    <section className="py-16 px-4">
      <div className="max-w-6xl mx-auto">
        <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-8 md:p-12 shadow-2xl">
          <div className="text-center mb-12 lg:text-left lg:max-w-2xl">
            <h2 className="text-4xl md:text-5xl font-semibold tracking-tight text-white mb-6">
              Trusted by growers{' '}
              <span className="bg-gradient-to-r from-yellow-400 via-pink-500 to-purple-600 bg-clip-text text-transparent">
                worldwide
              </span>
            </h2>
            <p className="text-lg text-gray-300">
              Join thousands of successful growers who trust SpaceGrow.ai to monitor and optimize their environments.
            </p>
          </div>
          
          <div className="flex flex-col lg:flex-row lg:items-end gap-8">
            {/* Featured stat */}
            <div className="flex flex-col-reverse justify-between gap-x-16 gap-y-8 rounded-2xl bg-white/10 backdrop-blur-sm border border-white/20 p-8 sm:w-3/5 sm:max-w-md sm:flex-row-reverse sm:items-end lg:w-72 lg:max-w-none lg:flex-none lg:flex-col lg:items-start hover:bg-white/20 transition-colors">
              <p className="flex-none text-3xl font-bold tracking-tight text-white">250,000</p>
              <div className="sm:w-80 sm:shrink lg:w-auto lg:flex-none">
                <p className="text-lg font-semibold tracking-tight text-white">Hours of continuous monitoring</p>
                <p className="mt-2 text-gray-300">
                  Our devices work around the clock to ensure your environment stays optimal.
                </p>
              </div>
            </div>
            
            {/* Stats grid */}
            <div className="grid grid-cols-2 gap-4 sm:gap-6 lg:gap-8 lg:flex-auto">
              {stats.map((stat) => (
                <div
                  key={stat.label}
                  className="rounded-2xl bg-white/10 backdrop-blur-sm border border-white/20 p-6 hover:bg-white/20 hover:border-yellow-400/30 transition-all duration-300 group"
                >
                  <p className="text-sm font-medium text-gray-400 group-hover:text-gray-300 transition-colors">{stat.label}</p>
                  <p className="mt-2 text-3xl font-bold tracking-tight text-white group-hover:text-yellow-400 transition-colors">{stat.value}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}