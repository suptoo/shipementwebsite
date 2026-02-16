// Type declarations for Deno runtime APIs used in Edge Functions.
// This file resolves TypeScript errors in VS Code when the Deno extension is not active.

declare namespace Deno {
    interface Env {
        get(key: string): string | undefined;
        set(key: string, value: string): void;
        delete(key: string): void;
        has(key: string): boolean;
        toObject(): Record<string, string>;
    }
    const env: Env;
}

// Deno std HTTP server
declare module 'https://deno.land/std@0.168.0/http/server.ts' {
    type Handler = (request: Request) => Response | Promise<Response>;
    export function serve(handler: Handler): void;
}

// Supabase JS client
declare module 'https://esm.sh/@supabase/supabase-js@2' {
    export interface SupabaseClient {
        auth: {
            getUser(): Promise<{
                data: { user: { id: string; email?: string;[key: string]: unknown } | null };
                error: Error | null;
            }>;
        };
        from(table: string): PostgrestQueryBuilder;
        storage: {
            from(bucket: string): StorageBucketApi;
        };
        rpc(fn: string, params?: Record<string, unknown>): Promise<{ data: unknown; error: Error | null }>;
    }

    export interface PostgrestQueryBuilder {
        select(columns?: string): PostgrestFilterBuilder;
        insert(data: Record<string, unknown> | Record<string, unknown>[]): PostgrestFilterBuilder;
        update(data: Record<string, unknown>): PostgrestFilterBuilder;
        delete(): PostgrestFilterBuilder;
        upsert(data: Record<string, unknown> | Record<string, unknown>[]): PostgrestFilterBuilder;
    }

    export interface PostgrestFilterBuilder {
        eq(column: string, value: unknown): PostgrestFilterBuilder;
        neq(column: string, value: unknown): PostgrestFilterBuilder;
        gt(column: string, value: unknown): PostgrestFilterBuilder;
        lt(column: string, value: unknown): PostgrestFilterBuilder;
        gte(column: string, value: unknown): PostgrestFilterBuilder;
        lte(column: string, value: unknown): PostgrestFilterBuilder;
        in(column: string, values: unknown[]): PostgrestFilterBuilder;
        is(column: string, value: unknown): PostgrestFilterBuilder;
        single(): Promise<{ data: Record<string, any> | null; error: Error | null }>;
        select(columns?: string): PostgrestFilterBuilder;
        then<TResult1 = { data: Record<string, any>[] | null; error: Error | null }>(
            onfulfilled?: (value: { data: Record<string, any>[] | null; error: Error | null }) => TResult1 | PromiseLike<TResult1>
        ): Promise<TResult1>;
        catch(onrejected?: (reason: unknown) => unknown): PostgrestFilterBuilder;
    }

    export interface StorageBucketApi {
        upload(path: string, data: ArrayBuffer | Uint8Array | Blob | File, options?: Record<string, unknown>): Promise<{ data: { path: string } | null; error: Error | null }>;
        getPublicUrl(path: string): { data: { publicUrl: string } };
        remove(paths: string[]): Promise<{ data: unknown; error: Error | null }>;
    }

    export interface SupabaseClientOptions {
        global?: {
            headers?: Record<string, string>;
        };
    }

    export function createClient(url: string, key: string, options?: SupabaseClientOptions): SupabaseClient;
}
