import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true,
        secure: false,
        rewrite: (path) => path.replace(/^\/api/, '/api')
      },
    },
  },
  build: {
    target: 'es2015',
    minify: 'terser',
    rollupOptions: {
      external: [],
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          antd: ['antd', '@ant-design/icons'],
          charts: ['@ant-design/charts']
        }
      }
    },
    commonjsOptions: {
      transformMixedEsModules: true
    },
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true
      }
    }
  },
  optimizeDeps: {
    include: ['@ant-design/charts', '@antv/g6', '@antv/g2']
  },
  define: {
    global: 'globalThis'
  },
  esbuild: {
    target: 'es2015'
  }
})
