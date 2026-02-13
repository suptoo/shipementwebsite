import React from 'react';

interface ButtonProps {
  onClick: () => void;
  label: string;
  className?: string;
}

const Button: React.FC<ButtonProps> = ({ onClick, label, className }) => {
  return (
    <button
      onClick={onClick}
      className={`bg-blue-500 text-white font-bold py-2 px-4 rounded ${className}`}
    >
      {label}
    </button>
  );
};

export default Button;