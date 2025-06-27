// utils/imageHelpers.ts

import { ProductImage } from '@/types/shop';

/**
 * Extracts the image URL from either a string or ProductImage object
 */
export function getImageUrl(image: string | ProductImage | undefined): string | undefined {
  if (!image) return undefined;
  
  if (typeof image === 'string') {
    return image;
  }
  
  return image.url;
}

/**
 * Gets the alt text for an image, with fallback
 */
export function getImageAlt(image: string | ProductImage | undefined, fallback: string = ''): string {
  if (!image || typeof image === 'string') {
    return fallback;
  }
  
  return image.alt || fallback;
}