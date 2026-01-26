import React from 'react'
import ReactDOM from 'react-dom/client'

function App() {
  return (
    <div>
      <h1>Hello from React + Vite!</h1>
      <p>Deployed to Azure Static Web Apps</p>
    </div>
  )
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />)
