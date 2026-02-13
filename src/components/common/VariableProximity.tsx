import React, { useEffect, useState } from 'react';

const parseFontVariationSettings = (settings: string): Record<string, number> => {
  const regex = /'(\w+)'\s+(\d+)/g;
  const result: Record<string, number> = {};
  let match;
  while ((match = regex.exec(settings)) !== null) {
    result[match[1]] = parseInt(match[2], 10);
  }
  return result;
};

interface VariableProximityProps {
  label: string;
  className?: string;
  fromFontVariationSettings: string;
  toFontVariationSettings: string;
  containerRef: React.RefObject<HTMLElement>;
  radius: number;
  falloff?: 'linear' | 'ease-in' | 'ease-out';
}

export const VariableProximity: React.FC<VariableProximityProps> = ({
  label,
  className = '',
  fromFontVariationSettings,
  toFontVariationSettings,
  containerRef,
  radius,
  falloff = 'linear',
}) => {
  const [fontVariation, setFontVariation] = useState(fromFontVariationSettings);

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      if (!containerRef.current) return;

      const rect = containerRef.current.getBoundingClientRect();
      const centerX = rect.left + rect.width / 2;
      const centerY = rect.top + rect.height / 2;

      const distance = Math.sqrt(
        Math.pow(e.clientX - centerX, 2) + Math.pow(e.clientY - centerY, 2)
      );

      let progress = Math.max(0, Math.min(1, 1 - distance / radius));

      // Apply falloff
      if (falloff === 'ease-in') {
        progress = progress * progress;
      } else if (falloff === 'ease-out') {
        progress = 1 - Math.pow(1 - progress, 2);
      }

      // Parse font variation settings
      const fromSettings = parseFontVariationSettings(fromFontVariationSettings);
      const toSettings = parseFontVariationSettings(toFontVariationSettings);

      // Interpolate
      const interpolated = Object.keys(fromSettings).map((key) => {
        const fromValue = fromSettings[key];
        const toValue = toSettings[key] || fromValue;
        const value = fromValue + (toValue - fromValue) * progress;
        return `'${key}' ${Math.round(value)}`;
      }).join(', ');

      setFontVariation(interpolated);
    };

    window.addEventListener('mousemove', handleMouseMove);
    return () => window.removeEventListener('mousemove', handleMouseMove);
  }, [containerRef, radius, falloff, fromFontVariationSettings, toFontVariationSettings]);

  return (
    <div
      className={`${className} transition-all duration-150 ease-out`}
      style={{
        fontVariationSettings: fontVariation,
        fontSize: '2rem',
        fontWeight: 400,
        letterSpacing: '-0.02em',
      }}
    >
      {label}
    </div>
  );
};

export default VariableProximity;
