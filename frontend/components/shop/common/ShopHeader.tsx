// components/shop/common/ShopHeader.tsx
'use client';

import { useState } from 'react';
import { Search, Filter, Grid, List } from 'lucide-react';

interface ShopHeaderProps {
  title: string;
  subtitle?: string;
  productCount?: number;
  onSearch?: (query: string) => void;
  onViewChange?: (view: 'grid' | 'list') => void;
  onFilterToggle?: () => void;
  showFilters?: boolean;
}

export function ShopHeader({ 
  title, 
  subtitle, 
  productCount, 
  onSearch, 
  onViewChange,
  onFilterToggle,
  showFilters = true
}: ShopHeaderProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [view, setView] = useState<'grid' | 'list'>('grid');

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSearch?.(searchQuery);
  };

  const handleViewChange = (newView: 'grid' | 'list') => {
    setView(newView);
    onViewChange?.(newView);
  };

  return (
    <div className="mb-8">
      {/* Title Section */}
      <div className="mb-6">
        <h1 className="text-4xl font-bold text-white mb-2">{title}</h1>
        {subtitle && (
          <p className="text-xl text-gray-300">{subtitle}</p>
        )}
        {typeof productCount === 'number' && (
          <p className="text-sm text-gray-400 mt-2">
            {productCount} {productCount === 1 ? 'product' : 'products'} found
          </p>
        )}
      </div>

      {/* Controls Section */}
      <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
        {/* Search Bar */}
        <form onSubmit={handleSearchSubmit} className="flex-1 max-w-md">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
            <input
              type="text"
              placeholder="Search products..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-3 bg-gray-800/80 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
            {searchQuery && (
              <button
                type="button"
                onClick={() => {
                  setSearchQuery('');
                  onSearch?.('');
                }}
                className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-white"
              >
                ×
              </button>
            )}
          </div>
        </form>

        {/* View Controls */}
        <div className="flex items-center gap-3">
          {/* Filter Toggle */}
          {showFilters && (
            <button
              onClick={onFilterToggle}
              className="flex items-center gap-2 px-4 py-2 bg-gray-800/80 border border-gray-600 rounded-lg text-gray-300 hover:text-white hover:border-gray-500 transition-colors"
            >
              <Filter className="w-4 h-4" />
              <span className="hidden sm:inline">Filters</span>
            </button>
          )}

          {/* View Toggle */}
          <div className="flex items-center bg-gray-800/80 border border-gray-600 rounded-lg overflow-hidden">
            <button
              onClick={() => handleViewChange('grid')}
              className={`p-2 transition-colors ${
                view === 'grid' 
                  ? 'bg-blue-600 text-white' 
                  : 'text-gray-400 hover:text-white hover:bg-gray-700'
              }`}
              title="Grid View"
            >
              <Grid className="w-4 h-4" />
            </button>
            <button
              onClick={() => handleViewChange('list')}
              className={`p-2 transition-colors ${
                view === 'list' 
                  ? 'bg-blue-600 text-white' 
                  : 'text-gray-400 hover:text-white hover:bg-gray-700'
              }`}
              title="List View"
            >
              <List className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}