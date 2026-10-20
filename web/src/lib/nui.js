import { writable } from 'svelte/store';
import defaultLocale from '../../../locales/en.json';

export const isBrowser = () => !window.invokeNative;

const visible = writable(isBrowser());

export const visibility = {
  subscribe: visible.subscribe,
  show: () => visible.set(true),
  hide: () => visible.set(false),
};

export const Team = writable(null);
export const Invite = writable(null);
export const Self = writable(0);
export const Locale = writable(defaultLocale.ui);

export function translate(dictionary, key, vars = {}) {
  const text = dictionary[key] ?? key;
  return Object.entries(vars).reduce((result, [name, value]) => result.replaceAll(`{${name}}`, value), text);
}

export async function fetchNui(event, data) {
  if (isBrowser()) return {};

  const resource = window.GetParentResourceName ? window.GetParentResourceName() : 'nui-frame-app';
  const response = await fetch(`https://${resource}/${event}`, {
    method: 'post',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data ?? {}),
  });

  return await response.json();
}

const listeners = new Map();

window.addEventListener('message', (event) => {
  const { action, data } = event.data;
  const handlers = listeners.get(action);
  if (handlers) handlers.forEach((handler) => handler(data));
});

export function onNuiMessage(action, handler) {
  const handlers = listeners.get(action) || [];
  handlers.push(handler);
  listeners.set(action, handlers);

  return () => {
    listeners.set(action, (listeners.get(action) || []).filter((h) => h !== handler));
  };
}
