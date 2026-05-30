export type EventListener = (payload: ESObject) => void;

export const EVENT_LANGUAGE_CHANGED: string = 'event.languageChanged';
export const EVENT_USER_LOGGED_IN: string = 'event.userLoggedIn';
export const EVENT_USER_LOGGED_OUT: string = 'event.userLoggedOut';
export const EVENT_THEME_CHANGED: string = 'event.themeChanged';
export const EVENT_TAB_DOUBLE_TAP: string = 'event.tabDoubleTap';
export const EVENT_REFRESH_REQUEST: string = 'event.refreshRequest';

class EventBusImpl {
  private listeners: Map<string, Set<EventListener>> = new Map<string, Set<EventListener>>();
  private sticky: Map<string, ESObject> = new Map<string, ESObject>();

  on(event: string, listener: EventListener): () => void {
    let set: Set<EventListener> | undefined = this.listeners.get(event);
    if (!set) {
      set = new Set<EventListener>();
      this.listeners.set(event, set);
    }
    set.add(listener);
    if (this.sticky.has(event)) {
      const payload: ESObject = this.sticky.get(event);
      this.sticky.delete(event);
      listener(payload);
    }
    return (): void => {
      this.off(event, listener);
    };
  }

  once(event: string, listener: EventListener): () => void {
    const wrapped: EventListener = (payload: ESObject): void => {
      this.off(event, wrapped);
      listener(payload);
    };
    return this.on(event, wrapped);
  }

  off(event: string, listener: EventListener): void {
    const set: Set<EventListener> | undefined = this.listeners.get(event);
    if (!set) {
      return;
    }
    set.delete(listener);
    if (set.size === 0) {
      this.listeners.delete(event);
    }
  }

  emit(event: string, payload?: ESObject): void {
    const set: Set<EventListener> | undefined = this.listeners.get(event);
    const data: ESObject = payload === undefined ? null : payload;
    if (!set || set.size === 0) {
      return;
    }
    set.forEach((l: EventListener): void => {
      l(data);
    });
  }

  emitSticky(event: string, payload?: ESObject): void {
    const set: Set<EventListener> | undefined = this.listeners.get(event);
    const data: ESObject = payload === undefined ? null : payload;
    if (!set || set.size === 0) {
      this.sticky.set(event, data);
      return;
    }
    set.forEach((l: EventListener): void => {
      l(data);
    });
  }

  hasListeners(event: string): boolean {
    const set: Set<EventListener> | undefined = this.listeners.get(event);
    return set !== undefined && set.size > 0;
  }

  listenerCount(event: string): number {
    const set: Set<EventListener> | undefined = this.listeners.get(event);
    return set ? set.size : 0;
  }

  removeAll(event?: string): void {
    if (event) {
      this.listeners.delete(event);
      this.sticky.delete(event);
      return;
    }
    this.listeners.clear();
    this.sticky.clear();
  }
}

export const EventBus: EventBusImpl = new EventBusImpl();
