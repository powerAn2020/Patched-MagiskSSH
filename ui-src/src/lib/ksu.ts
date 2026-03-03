import * as kernelsu from 'kernelsu';

// Simple check if kernelsu API is injected into the environment
// Depending on how kernelsu package works, it might just wrap window.ksu or window.ksu.exec.
// The `kernelsu` npm package actually exports exec, spawn, full, etc.
const isMock = import.meta.env.DEV;

export async function exec(cmd: string): Promise<{ errno: number, stdout: string, stderr: string }> {
    if (isMock) {
        console.log(`[Mock KSU Exec]: ${cmd}`);
        return { errno: 0, stdout: `Mock output for: ${cmd}`, stderr: '' };
    }
    return await kernelsu.exec(cmd);
}

export function spawn(
    cmd: string,
    args: string[],
    onData: (data: string) => void,
    onError: (err: string) => void,
    onExit: (code: number) => void
) {
    if (isMock) {
        console.log(`[Mock KSU Spawn]: ${cmd} ${args.join(' ')}`);
        const timer = setInterval(() => onData(`Mock log line from ${cmd} at ${new Date().toISOString()}\n`), 1000);
        setTimeout(() => {
            clearInterval(timer);
            onExit(0);
        }, 5000);
        return () => clearInterval(timer);
    }

    const child = kernelsu.spawn(cmd, args) as any;

    child.on('data', (chunk: any) => onData(chunk.toString()));
    child.on('error', (err: any) => onError(err.toString()));
    child.on('exit', (code: number) => onExit(code));

    // Return a cleanup/kill function. If kernelsu doesn't support child.kill(), we might execute a kill command natively
    return () => {
        // If child process in kernelsu has a kill function
        if (typeof child.kill === 'function') {
            child.kill();
        } else {
            // Fallback
            kernelsu.exec(`pkill -f "${cmd}"`);
        }
    };
}
