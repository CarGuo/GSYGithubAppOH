import common from '@ohos.app.ability.common';
import { OAuthClientConfig } from './LoginUseCase';
import { DEFAULT_OAUTH_REDIRECT_URI } from './OauthService';

const LOCAL_OAUTH_RAWFILE: string = 'oauth.local.json';

class OAuthLocalJson {
  client_id?: string;
  clientId?: string;
  client_secret?: string;
  clientSecret?: string;
  redirect_uri?: string;
  redirectUri?: string;
}

export class OAuthRuntimeConfig {
  clientId: string = '';
  clientSecret: string = '';
  redirectUri: string = DEFAULT_OAUTH_REDIRECT_URI;

  isValid(): boolean {
    return this.clientId.length > 0 && this.clientSecret.length > 0;
  }

  toClientConfig(): OAuthClientConfig {
    return new OAuthClientConfig(this.clientId, this.clientSecret, this.redirectUri);
  }
}

export class OAuthLocalConfigLoader {
  private static cached: OAuthRuntimeConfig | null = null;

  static clearCache(): void {
    OAuthLocalConfigLoader.cached = null;
  }

  static async load(host: Object): Promise<OAuthRuntimeConfig> {
    if (OAuthLocalConfigLoader.cached !== null) {
      return OAuthLocalConfigLoader.cached as OAuthRuntimeConfig;
    }
    const empty: OAuthRuntimeConfig = new OAuthRuntimeConfig();
    try {
      const ctx: common.UIAbilityContext = getContext(host) as common.UIAbilityContext;
      const bytes: Uint8Array = await ctx.resourceManager.getRawFileContent(LOCAL_OAUTH_RAWFILE);
      const text: string = OAuthLocalConfigLoader.decodeUtf8(bytes);
      const parsed: OAuthLocalJson = JSON.parse(text) as OAuthLocalJson;
      const cfg: OAuthRuntimeConfig = OAuthLocalConfigLoader.fromJson(parsed);
      OAuthLocalConfigLoader.cached = cfg;
      return cfg;
    } catch (_e) {
      OAuthLocalConfigLoader.cached = empty;
      return empty;
    }
  }

  private static fromJson(obj: OAuthLocalJson): OAuthRuntimeConfig {
    const cfg: OAuthRuntimeConfig = new OAuthRuntimeConfig();
    cfg.clientId = OAuthLocalConfigLoader.pickString(obj.client_id, obj.clientId);
    cfg.clientSecret = OAuthLocalConfigLoader.pickString(obj.client_secret, obj.clientSecret);
    const redirect: string = OAuthLocalConfigLoader.pickString(obj.redirect_uri, obj.redirectUri);
    cfg.redirectUri = redirect.length > 0 ? redirect : DEFAULT_OAUTH_REDIRECT_URI;
    return cfg;
  }

  private static pickString(primary: string | undefined, fallback: string | undefined): string {
    if (primary !== undefined && primary !== null && primary.length > 0) {
      return primary.trim();
    }
    if (fallback !== undefined && fallback !== null && fallback.length > 0) {
      return fallback.trim();
    }
    return '';
  }

  private static decodeUtf8(bytes: Uint8Array): string {
    let out: string = '';
    let i: number = 0;
    while (i < bytes.length) {
      const b0: number = bytes[i];
      if (b0 < 0x80) {
        out += String.fromCharCode(b0);
        i += 1;
      } else if ((b0 & 0xE0) === 0xC0 && i + 1 < bytes.length) {
        const b1: number = bytes[i + 1];
        out += String.fromCharCode(((b0 & 0x1F) << 6) | (b1 & 0x3F));
        i += 2;
      } else if ((b0 & 0xF0) === 0xE0 && i + 2 < bytes.length) {
        const b1: number = bytes[i + 1];
        const b2: number = bytes[i + 2];
        out += String.fromCharCode(((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F));
        i += 3;
      } else {
        out += '?';
        i += 1;
      }
    }
    return out;
  }
}
