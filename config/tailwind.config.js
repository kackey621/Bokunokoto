const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  important: '.tailadmin-scope',
  corePlugins: {
    preflight: false,
  },
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  darkMode: 'class',
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
        satoshi: ['Satoshi', 'sans-serif'],
      },
      colors: {
        // CoreUI / TailAdmin specific colors
        primary: {
          DEFAULT: '#3C50E0',
          dark: '#80CAEE',
        },
        secondary: {
          DEFAULT: '#80CAEE',
        },
        stroke: {
          DEFAULT: '#E2E8F0',
          dark: '#2E3A47',
          form: '#d5d9e2',
        },
        boxdark: {
          DEFAULT: '#24303F',
          2: '#313D4A',
        },
        body: {
          DEFAULT: '#64748B',
          dark: '#AEB7C0',
        },
        whiten: {
          DEFAULT: '#F1F5F9',
        },
        danger: {
          DEFAULT: '#DC3545',
        },
        success: {
          DEFAULT: '#219653',
        },
        warning: {
          DEFAULT: '#F9C107',
        },
        meta: {
          1: '#DC3545',
          2: '#EFF2F7',
          3: '#10B981',
          4: '#313D4A',
          5: '#259AE6',
          6: '#FFBA00',
          7: '#FF6766',
          8: '#F0950C',
          9: '#E5E7EB',
        },
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
  ]
}
