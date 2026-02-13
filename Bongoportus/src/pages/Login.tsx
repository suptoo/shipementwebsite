import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

// This page redirects to the proper login in components/auth/Login.tsx
const Login: React.FC = () => {
    const { user } = useAuth();
    
    if (user) {
        return <Navigate to="/" />;
    }

    // The actual Login component is rendered via routes in App.tsx
    return null;
};

export default Login;