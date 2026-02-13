import React, { useRef, useEffect } from 'react';

// Lightweight shader-inspired canvas backdrop influenced by github.com/zavalit/bayer-dithering-webgl-demo
export interface PixelBlastProps {
  variant?: 'circle' | 'square';
  pixelSize?: number;
  color?: string;
  patternScale?: number;
  patternDensity?: number;
  pixelSizeJitter?: number;
  enableRipples?: boolean;
  rippleSpeed?: number;
  rippleThickness?: number;
  rippleIntensityScale?: number;
  liquid?: boolean;
  liquidStrength?: number;
  liquidRadius?: number;
  liquidWobbleSpeed?: number;
  speed?: number;
  edgeFade?: number;
  transparent?: boolean;
}

const PixelBlast: React.FC<PixelBlastProps> = ({
  variant = 'square',
  pixelSize = 8,
  color = '#8B5CF6',
  patternScale = 2,
  patternDensity = 1,
  pixelSizeJitter = 0.3,
  enableRipples = true,
  rippleSpeed = 0.3,
  rippleThickness = 0.1,
  rippleIntensityScale = 1.2,
  liquid = false,
  liquidStrength = 0.1,
  liquidRadius = 1,
  liquidWobbleSpeed = 4,
  speed = 0.4,
  edgeFade = 0.2,
  transparent = false,
}) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const pixelRatio = window.devicePixelRatio || 1;

    const resize = () => {
      const { clientWidth, clientHeight } = canvas;
      canvas.width = clientWidth * pixelRatio;
      canvas.height = clientHeight * pixelRatio;
      ctx.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
    };

    resize();
    window.addEventListener('resize', resize);

    let frame = 0;
    let raf: number;

    const render = () => {
      const width = canvas.clientWidth;
      const height = canvas.clientHeight;
      ctx.clearRect(0, 0, width, height);

      if (!transparent) {
        const gradient = ctx.createLinearGradient(0, 0, width, height);
        gradient.addColorStop(0, '#0f172a');
        gradient.addColorStop(1, '#1e1b4b');
        ctx.fillStyle = gradient;
        ctx.fillRect(0, 0, width, height);
      }

      const cols = Math.ceil(width / pixelSize);
      const rows = Math.ceil(height / pixelSize);
      const time = frame * speed * 0.01;
      const centerX = width / 2;
      const centerY = height / 2;
      ctx.globalCompositeOperation = 'lighter';

      for (let y = 0; y < rows; y++) {
        for (let x = 0; x < cols; x++) {
          const px = x * pixelSize;
          const py = y * pixelSize;
          const nx = x / cols;
          const ny = y / rows;

          const wave = Math.sin((nx * patternScale + time) * 4) + Math.cos((ny * patternScale - time) * 3);
          const dither = Math.sin((nx + ny + time) * patternDensity * Math.PI);
          let intensity = (wave + dither) * 0.25 + 0.5;

          if (enableRipples) {
            const dx = px - centerX;
            const dy = py - centerY;
            const dist = Math.sqrt(dx * dx + dy * dy);
            const ripple = Math.sin(dist * rippleThickness - time * rippleSpeed * 6);
            intensity += ripple * rippleIntensityScale * 0.25;
          }

          if (liquid) {
            const wobble = Math.sin((nx + ny) * liquidRadius + time * liquidWobbleSpeed);
            intensity += wobble * liquidStrength;
          }

          const fadeX = Math.min(px / width, 1 - px / width);
          const fadeY = Math.min(py / height, 1 - py / height);
          const fade = Math.min(fadeX, fadeY);
          intensity *= 1 - edgeFade + fade * edgeFade;

          const alpha = Math.max(0, Math.min(1, intensity));
          ctx.fillStyle = hexToRgba(color, alpha);
          const jitter = (Math.random() - 0.5) * pixelSize * pixelSizeJitter;
          const size = Math.max(2, pixelSize + jitter);

          if (variant === 'circle') {
            ctx.beginPath();
            ctx.arc(px, py, size / 2, 0, Math.PI * 2);
            ctx.fill();
          } else {
            ctx.fillRect(px, py, size, size);
          }
        }
      }

      ctx.globalCompositeOperation = 'source-over';
      frame += 1;
      raf = requestAnimationFrame(render);
    };

    raf = requestAnimationFrame(render);

    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener('resize', resize);
    };
  }, [
    variant,
    pixelSize,
    color,
    patternScale,
    patternDensity,
    pixelSizeJitter,
    enableRipples,
    rippleSpeed,
    rippleThickness,
    rippleIntensityScale,
    liquid,
    liquidStrength,
    liquidRadius,
    liquidWobbleSpeed,
    speed,
    edgeFade,
    transparent,
  ]);

  return <canvas ref={canvasRef} className="absolute inset-0 w-full h-full" />;
};

export default PixelBlast;

const hexToRgba = (hex: string, alpha = 1) => {
  const sanitized = hex.replace('#', '');
  const bigint = parseInt(sanitized, 16);
  const r = (bigint >> 16) & 255;
  const g = (bigint >> 8) & 255;
  const b = bigint & 255;
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
};
