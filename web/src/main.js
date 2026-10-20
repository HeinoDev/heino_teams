import { mount } from 'svelte';
import './app.css';
import App from './App.svelte';
import { isBrowser } from './lib/nui.js';

const target = document.getElementById('app');

if (isBrowser()) {
  target.style.height = '100vh';
  target.style.background = '#0b0b0b';
}

export default mount(App, { target });
