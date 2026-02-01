module.exports = {
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
          neutral: '#424242',
          'base-100': '#ffffff',
          'base-200': '#fafafa',
          'base-300': '#f5f5f5',
          'base-content': '#212121',
          '--rounded-btn': '1.9rem',
          '--tab-border': '2px',
          '--tab-radius': '.5rem'
        }
      }
    ]
  }
}
