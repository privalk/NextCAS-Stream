<script lang="ts" setup>
import { nextTick, onMounted, provide, ref, shallowRef, watch } from 'vue'
import { NextStream, PresetCameraConfig } from '@nextcas/stream'
import gsap from 'gsap'
import Send from './components/send.vue'
import MessageBoard from './components/messageBoard.vue'
import { useAppStore } from './store/app'
import { useMessageStore } from './store/messages'
import Menus from './components/menus.vue'
import { useConfigStore } from './store/config'

const container = ref()
const ready = ref(false)
const started = ref(false)
const closed = ref(false)
const app = useAppStore()
const config = useConfigStore()

const progressBarWidth = ref(0) // 用于控制进度条的宽度

onMounted(async () => {
  init()
})

const stream = shallowRef<NextStream>()
const openMessage = ref(false)
const messageBoard = ref<HTMLElement>()

const messageBoardTween = shallowRef<gsap.core.Tween>()

watch(openMessage, (v) => {
  if (!messageBoard.value) return

  const width = messageBoard.value.clientWidth
  if (!messageBoardTween.value) {
    messageBoardTween.value = gsap.to(messageBoard.value, {
      translateX: width/2,
      duration: 0.5,
      ease: 'power2.out',
    })
  }
  if (v) messageBoardTween.value.play()
  else messageBoardTween.value.reverse()
})

watch(() => config.currentLocation, (v) => {
  if (v) stream.value?.setCamera(v)
})

async function init() {
  try {
    simulateProgress() // 开始伪加载进度条动画
    closed.value = false
    await nextTick()
    stream.value = await NextStream.createLocal({
      ip: '127.0.0.1',
      actorId: 'actor_117034',
      container: container.value,
      avatarId: 'avatar_497449',
      scene: { id: '6538b8f14b2c896b74ebc0f1', type: 'nus' },
      resolutionRatio: "1080p",
    })

    ready.value = true


    stream.value.on('close', () => {
      closed.value = true
      ready.value = false
      started.value = false
    })
    stream.value?.setCamera(PresetCameraConfig.Full)
  }
  catch (error) {
    console.log(error)
  }
}

function simulateProgress() {
  gsap.to(progressBarWidth, {
    value: 100,
    duration: 10, // 设置进度条的总时长
    ease: 'power2.out',

  })
}

function _startRender() {
  if (stream.value) stream.value.start()
  nextTick(() => { started.value = true })
}

function _closeRender() {
  // 关闭渲染的逻辑
}

const messageStore = useMessageStore()

function sendText(text: string) {
  if (stream.value) {
    const { observer, reqId } = stream.value.ask(text)
    messageStore.sendMessage(text, reqId)
    if (!openMessage.value) openMessage.value = true

    observer?.subscribe((res) => {
      messageStore.onReply(res.content, res.reqId)
    })
  }
}

provide('streamSDK', () => stream.value)
</script>

<template>
  <div class="w-full h-full relative flex">
    <!-- 客户端关闭 -->
    <template v-if="closed">
      <div class="flex-center">
        <button @click="init">重新启动</button>
        <span>客户端已关闭</span>
      </div>
    </template>

    <!-- 主体内容 -->
    <template v-else>
      <div ref="container" class="w-full h-full bg-black absolute"></div>
      
      <!-- 进度条 -->
      <div v-if="!ready" class="progress-bar-container">
        <div class="progress-bar" :style="{ width: progressBarWidth + '%' }"></div>
      </div>

      <template v-if="started">
        <div v-if="ready && app.token" class="h-full z-100 w-full relative">
          <div ref="messageBoard" class="h-full absolute bottom-0 left-[-50%] w-1/2 py-18">
            <MessageBoard v-model:open="openMessage" :messages="messageStore.messages" />
          </div>
          <div class="w-16 top-0 bottom-0 absolute right-4">
            <Menus />
          </div>
          <div class="absolute bottom-0 left-0 w-full p-4">
            <Send @send="sendText" />
          </div>
        </div>
      </template>

      <div v-else class="w-full h-full z-100 flex justify-center items-center">
        <div class="flex justify-center items-center full-screen-gif">
          <!-- 显示加载 GIF -->
          <img src=".\assets\gifs\default.f84195f1.gif" alt="Loading" class="w-full h-full" />
        </div>
        
        <button v-if="ready" @click="_startRender" class="start-btn">
          启动
        </button>
      </div>
    </template>
  </div>
</template>

<style scoped>
.start-btn {
  
  background-color: #5cabff;
  color: white;
  font-size: 1.25rem;
  padding: 12px 24px;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
  margin-top: 100px;
  z-index: 0;
}

.start-btn:hover {
  background-color: #0056b3;
  transform: scale(1.05);
}

.start-btn:focus {
  outline: none;
}

.progress-bar-container {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 80%;
  height: 5px;
  background-color: rgba(0, 0, 0, 0.2);
  z-index: 200 ;
}

.progress-bar {
  height: 100%;
  background-color: #ffffff;
  z-index: 200 ;
}

.w-full {
  width: 100%;
}

.h-full {
  height: 100%;
}

.flex-center {
  display: flex;
  justify-content: center;
  align-items: center;
}

.flex {
  display: flex;
}

.justify-center {
  justify-content: center;
}

.items-center {
  align-items: center;
}

.full-screen-gif {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
}
</style>
