const defaultTheme = require('tailwindcss/defaultTheme')

// Wippli look (matches app.wippli.ai): IBM Plex Sans, action magenta #CB007B,
// 20px boxes and pill buttons. The theme name stays "docuseal" because the
// layouts set data-theme="docuseal".
module.exports = {
  theme: {
    extend: {
      fontFamily: {
        sans: ['"IBM Plex Sans"', ...defaultTheme.fontFamily.sans]
      }
    }
  },
  plugins: [
    require('daisyui')
  ],
  daisyui: {
    themes: [
      {
        docuseal: {
          'color-scheme': 'light',
          primary: '#e5e5e5',
          secondary: '#9e9e9e',
          accent: '#616161',
          neutral: '#CB007B',
          'neutral-focus': '#A80066',
          'neutral-content': '#ffffff',
          'base-100': '#ffffff',
          'base-200': '#fafafa',
          'base-300': '#f5f5f5',
          'base-content': '#212121',
          '--rounded-box': '1.25rem',
          '--rounded-btn': '2.5rem',
          '--rounded-badge': '1.9rem',
          '--tab-border': '2px',
          '--tab-radius': '.5rem'
        }
      }
    ]
  }
}
