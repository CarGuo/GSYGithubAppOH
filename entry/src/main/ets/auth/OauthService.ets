import { LoginUseCase, DefaultLoginUseCase, LoginOutcome } from './LoginUseCase';
import { LoginExpiredBus } from '../net/HttpManager';
import { HOST_WEB } from '../net/Address';
import { Url } from '../utils/Url';

export const DEFAULT_OAUTH_REDIRECT_URI: string = 'gsygithubapp://authed';
export const DEFAULT_OAUTH_SCOPE: string = 'user,repo,gist,notifications,read:org,workflow';
const STATE_CHARS: string = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
const STATE_LENGTH: number = 16;

class OauthServiceImpl {
  private useCase: LoginUseCase = DefaultLoginUseCase;
  private lastState: string = '';

  setUseCase(useCase: LoginUseCase): void {
    this.useCase = useCase;
  }

  resetUseCase(): void {
    this.useCase = DefaultLoginUseCase;
  }

  getLastState(): string {
    return this.lastState;
  }

  resetState(): void {
    this.lastState = '';
  }

  buildAuthorizeUrl(clientId: string,
                    redirectUri: string = DEFAULT_OAUTH_REDIRECT_URI,
                    scope: string = DEFAULT_OAUTH_SCOPE,
                    state?: string): string {
    const safeClient: string = clientId ? clientId : '';
    const safeRedirect: string = redirectUri && redirectUri.length > 0
      ? redirectUri
      : DEFAULT_OAUTH_REDIRECT_URI;
    const safeScope: string = scope && scope.length > 0 ? scope : DEFAULT_OAUTH_SCOPE;
    const finalState: string = state !== undefined && state !== null && state.length > 0
      ? state
      : this.generateState();
    this.lastState = finalState;
    const params: Record<string, string> = {
      'client_id': safeClient,
      'redirect_uri': safeRedirect,
      'scope': safeScope,
      'state': finalState,
    };
    const query: string = Url.buildQuery(params);
    return `${HOST_WEB}login/oauth/authorize?${query}`;
  }

  generateState(): string {
    let out: string = '';
    for (let i: number = 0; i < STATE_LENGTH; i++) {
      const r: number = Math.floor(Math.random() * STATE_CHARS.length);
      out += STATE_CHARS.charAt(r);
    }
    this.lastState = out;
    return out;
  }

  validateState(received: string): boolean {
    if (!received || received.length === 0) {
      return false;
    }
    if (this.lastState.length === 0) {
      return false;
    }
    return this.lastState === received;
  }

  async exchangeOAuthCode(code: string): Promise<LoginOutcome> {
    const safeCode: string = (code ? code : '').trim();
    try {
      const res: LoginOutcome = await this.useCase.exchangeOAuthCode(safeCode);
      if (!res.result) {
        LoginExpiredBus.publish();
      }
      return res;
    } catch (e) {
      LoginExpiredBus.publish();
      throw e as Error;
    }
  }
}

export const OauthService: OauthServiceImpl = new OauthServiceImpl();
