import * as kernelsu from 'kernelsu';

const isMock = import.meta.env.DEV;

// --- Module path resolution via ksu.moduleInfo() ----------------------------

let cachedModDir: string | null = null;

function getModDir(): string {
    if (cachedModDir) return cachedModDir;
    if (isMock) {
        cachedModDir = '/data/adb/modules/MagiskSSH';
        return cachedModDir;
    }
    try {
        const info = kernelsu.moduleInfo();
        // moduleInfo() returns a string, typically the module base directory
        // e.g. "/data/adb/modules/MagiskSSH"
        cachedModDir = info.trim();
    } catch {
        cachedModDir = '/data/adb/modules/MagiskSSH';
    }
    return cachedModDir;
}

function getApiScript(): string {
    return `${getModDir()}/scripts/api.sh`;
}

// --- exec wrapper (blocking, for quick operations) ---------------------------

export async function exec(cmd: string): Promise<{ errno: number; stdout: string; stderr: string }> {
    if (isMock) {
        console.log(`[Mock KSU Exec]: ${cmd}`);
        return mockExec(cmd);
    }
    return await kernelsu.exec(cmd);
}

// High-level: call api.sh <action> [args...]
export async function api(action: string, ...args: string[]): Promise<{ errno: number; stdout: string; stderr: string }> {
    const cmd = `sh ${getApiScript()} ${action} ${args.join(' ')}`.trim();
    return exec(cmd);
}

// High-level: call api.sh <action> and pipe base64-encoded stdin content
export async function apiWithStdin(action: string, content: string): Promise<{ errno: number; stdout: string; stderr: string }> {
    const b64 = btoa(unescape(encodeURIComponent(content)));
    const cmd = `echo '${b64}' | sh ${getApiScript()} ${action}`;
    return exec(cmd);
}

// --- spawn wrapper (non-blocking, for streaming) ------------------------------

export function spawn(
    cmd: string,
    args: string[],
    onData: (data: string) => void,
    onError: (err: string) => void,
    onExit: (code: number) => void
) {
    if (isMock) {
        console.log(`[Mock KSU Spawn]: ${cmd} ${args.join(' ')}`);
        const timer = setInterval(
            () => onData(`[${new Date().toLocaleTimeString()}] Mock sshd log: Connection from 192.168.1.${Math.floor(Math.random() * 255)}\n`),
            2000
        );
        setTimeout(() => {
            clearInterval(timer);
            onExit(0);
        }, 60000);
        return () => clearInterval(timer);
    }

    const child = kernelsu.spawn(cmd, args);

    child.stdout.on('data', (chunk: string) => onData(chunk));
    child.stderr.on('data', (chunk: string) => onError(chunk));
    child.on('exit', (code: number) => onExit(code));

    return () => {
        // kernelsu ChildProcess has no kill(), so we pkill the process
        kernelsu.exec(`pkill -f "${cmd}"`);
    };
}

// High-level: spawn api.sh tail_log (non-blocking log stream)
export function spawnLogTail(
    onData: (data: string) => void,
    onError: (err: string) => void,
    onExit: (code: number) => void
) {
    return spawn('sh', [getApiScript(), 'tail_log'], onData, onError, onExit);
}

// --- Mock responses for dev/PC testing ---------------------------------------

function mockExec(cmd: string): { errno: number; stdout: string; stderr: string } {
    if (cmd.includes('status')) {
        return { errno: 0, stdout: '{"running":true,"pid":"1234","port":"22"}', stderr: '' };
    }
    if (cmd.includes('start')) {
        return { errno: 0, stdout: '{"errno":0,"stdout":"sshd started (pid 1234)","stderr":""}', stderr: '' };
    }
    if (cmd.includes('stop')) {
        return { errno: 0, stdout: '{"errno":0,"stdout":"sshd stopped","stderr":""}', stderr: '' };
    }
    if (cmd.includes('read_config')) {
        const cfg = [
            'Port 22',
            'PermitRootLogin yes',
            'PasswordAuthentication no',
            'PubkeyAuthentication yes',
            'AuthorizedKeysFile .ssh/authorized_keys',
            'Subsystem sftp /usr/libexec/sftp-server',
        ].join('\n');
        // Return base64-encoded mock config
        return { errno: 0, stdout: btoa(unescape(encodeURIComponent(cfg))), stderr: '' };
    }
    if (cmd.includes('read_keys')) {
        return {
            errno: 0,
            stdout: 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExample1234567890 user@device\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgExample admin@workstation',
            stderr: '',
        };
    }
    if (cmd.includes('read_log')) {
        return {
            errno: 0,
            stdout: Array.from({ length: 10 }, (_, i) => `[mock] sshd log line ${i + 1}`).join('\n'),
            stderr: '',
        };
    }
    return { errno: 0, stdout: '{"errno":0,"stdout":"OK","stderr":""}', stderr: '' };
}
