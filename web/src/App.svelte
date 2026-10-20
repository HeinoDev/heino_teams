<script>
  import { onMount } from 'svelte';
  import { fade, scale } from 'svelte/transition';
  import { quintOut } from 'svelte/easing';
  import { visibility, fetchNui, onNuiMessage, isBrowser, translate, Team, Invite, Self, Locale } from './lib/nui.js';

  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const duration = (ms) => (reduceMotion ? 0 : ms);

  let nearby = [];
  let targetId = '';
  let busy = false;

  $: isLeader = $Team && $Team.leader === $Self;
  $: canInvite = isLeader && $Team.members.length < $Team.maxSize;
  $: tr = (key, vars) => translate($Locale, key, vars);

  async function close() {
    await fetchNui('close');
    visibility.hide();
  }

  async function loadNearby() {
    if (!canInvite) {
      nearby = [];
      return;
    }
    const list = await fetchNui('nearby');
    nearby = Array.isArray(list) ? list : [];
  }

  async function run(event, data) {
    if (busy) return;
    busy = true;
    await fetchNui(event, data);
    busy = false;
    if (event === 'create' || event === 'accept' || event === 'kick' || event === 'invite') loadNearby();
  }

  async function invite(id) {
    const value = Number(id);
    if (!value) return;
    await run('invite', { id: value });
    targetId = '';
  }

  onMount(() => {
    const onKeydown = (event) => {
      if ($visibility && event.code === 'Escape') close();
    };
    window.addEventListener('keydown', onKeydown);

    const offs = [
      onNuiMessage('open', (data) => {
        Locale.set(data.locale);
        Team.set(data.team);
        Invite.set(data.invite);
        Self.set(data.self);
        visibility.show();
        loadNearby();
      }),
      onNuiMessage('close', () => visibility.hide()),
      onNuiMessage('team', (team) => {
        Team.set(team);
        loadNearby();
      }),
      onNuiMessage('invite', (invite) => Invite.set(invite)),
    ];

    if (isBrowser()) {
      Self.set(1);
      Team.set({ id: 1, leader: 1, maxSize: 4, members: [{ id: 1, name: 'Heino', leader: true }, { id: 7, name: 'Bach', leader: false }] });
      nearby = [{ id: 12, name: 'Mani' }];
    }

    return () => {
      window.removeEventListener('keydown', onKeydown);
      offs.forEach((off) => off());
    };
  });
</script>

{#if $visibility}
  <div class="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50 select-none" transition:fade={{ duration: duration(150) }}>
    <div
      class="w-[420px] h-[500px] bg-[#121212] rounded shadow-2xl flex flex-col overflow-hidden border border-[#333333]"
      in:scale={{ start: 0.97, duration: duration(200), easing: quintOut }}
      out:scale={{ start: 0.97, duration: duration(150), easing: quintOut }}
    >
      <header class="bg-[#1a1a1a] border-b border-[#333333] px-4 py-3 flex justify-between items-center">
        <h1 class="text-white font-semibold tracking-tight">{tr('title')}</h1>
        <div class="flex items-center gap-3">
          {#if $Team}
            <span class="num bg-[#252525] border border-[#333333] rounded px-2 py-0.5 text-xs text-blue-400 font-medium">
              <i class="fa-solid fa-users mr-1"></i>{$Team.members.length}/{$Team.maxSize}
            </span>
          {/if}
          <button class="text-gray-400 hover:text-white w-6 h-6 flex items-center justify-center" on:click={close} aria-label={tr('close')}>
            <i class="fa-solid fa-xmark"></i>
          </button>
        </div>
      </header>

      <div class="flex-1 overflow-auto p-4 flex flex-col gap-4 min-h-0">
        {#if $Invite}
          <div class="bg-[#1e1e1e] border border-blue-500 rounded p-3 flex flex-col gap-3">
            <p class="text-sm text-gray-300">{tr('invite_banner', { name: $Invite.inviterName })}</p>
            <div class="flex gap-2">
              <button class="btn flex-1 bg-blue-500 hover:bg-blue-400 text-white text-sm font-medium rounded py-1.5" on:click={() => run('accept')}>{tr('accept')}</button>
              <button class="btn flex-1 bg-[#252525] hover:bg-[#2c2c2c] text-gray-300 text-sm font-medium rounded py-1.5" on:click={() => run('decline')}>{tr('decline')}</button>
            </div>
          </div>
        {/if}

        {#if !$Team}
          <div class="flex-1 flex flex-col items-center justify-center gap-3">
            <p class="text-gray-400 text-sm">{tr('not_in_team')}</p>
            <button class="btn bg-blue-500 hover:bg-blue-400 text-white text-sm font-medium rounded px-4 py-2" on:click={() => run('create')}>
              <i class="fa-solid fa-plus mr-1"></i> {tr('create_team')}
            </button>
          </div>
        {:else}
          <div class="flex flex-col gap-2">
            {#each $Team.members as member (member.id)}
              <div class="card bg-[#1e1e1e] border border-[#333333] rounded px-3 py-2 flex items-center justify-between">
                <div class="flex items-center gap-2">
                  {#if member.leader}
                    <i class="fa-solid fa-crown text-xs text-blue-400"></i>
                  {:else}
                    <i class="fa-solid fa-user text-xs text-gray-500"></i>
                  {/if}
                  <span class="text-white text-sm">{member.name}</span>
                  <span class="num text-xs text-gray-500">#{member.id}</span>
                  {#if member.id === $Self}
                    <span class="text-xs text-gray-400">{tr('self_tag')}</span>
                  {/if}
                </div>
                {#if isLeader && member.id !== $Self}
                  <button class="text-gray-500 hover:text-red-400 text-sm" on:click={() => run('kick', { id: member.id })} aria-label={tr('remove_member')}>
                    <i class="fa-solid fa-user-minus"></i>
                  </button>
                {/if}
              </div>
            {/each}
          </div>

          {#if canInvite}
            <div class="flex flex-col gap-2">
              <span class="text-gray-400 text-xs">{tr('invite_player')}</span>
              <form class="flex gap-2" on:submit|preventDefault={() => invite(targetId)}>
                <input
                  class="flex-1 bg-[#1e1e1e] border border-[#333333] focus:border-blue-500 outline-none rounded px-3 py-1.5 text-sm text-white placeholder-gray-500"
                  type="text"
                  inputmode="numeric"
                  maxlength="4"
                  placeholder={tr('player_id_placeholder')}
                  bind:value={targetId}
                  on:input={() => (targetId = String(targetId).replace(/\D/g, ''))}
                />
                <button class="btn bg-blue-500 hover:bg-blue-400 text-white text-sm font-medium rounded px-4" type="submit">{tr('invite')}</button>
              </form>

              {#if nearby.length}
                <span class="text-gray-400 text-xs mt-1">{tr('nearby')}</span>
                {#each nearby as player (player.id)}
                  <div class="card bg-[#1e1e1e] border border-[#333333] hover:border-blue-500 rounded px-3 py-2 flex items-center justify-between">
                    <div class="flex items-center gap-2">
                      <span class="text-white text-sm">{player.name}</span>
                      <span class="num text-xs text-gray-500">#{player.id}</span>
                    </div>
                    <button class="text-blue-400 hover:text-blue-300 text-sm" on:click={() => invite(player.id)}>{tr('invite')}</button>
                  </div>
                {/each}
              {/if}
            </div>
          {:else if isLeader}
            <p class="text-gray-500 text-xs text-center">{tr('team_full')}</p>
          {/if}

          <button class="btn mt-auto shrink-0 bg-[#252525] hover:bg-red-500/30 text-gray-300 text-sm font-medium rounded py-2" on:click={() => run('leave')}>
            {tr('leave_team')}
          </button>
        {/if}
      </div>
    </div>
  </div>
{/if}
