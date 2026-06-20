const { isLocalImagePath, saveImage } = require('../../utils/photo-save')

// 全屏照片查看器：左右滑动 + 一键保存原图到相册
Component({
  properties: {
    show: { type: Boolean, value: false },
    urls: { type: Array, value: [] },
    current: { type: Number, value: 0 },
  },

  data: {
    idx: 0,
    saving: false,
    saveText: '保存原图',
  },

  observers: {
    current(v) {
      this.setIndex(Number(v) || 0)
    },
    urls() {
      this.setIndex(this.data.idx)
    },
  },

  methods: {
    setIndex(idx) {
      const url = this.data.urls[idx] || ''
      this.setData({
        idx,
        saveText: isLocalImagePath(url) ? '保存到相册' : '保存原图',
      })
    },

    onChange(e) {
      this.setIndex(e.detail.current)
    },

    close() {
      this.triggerEvent('close')
    },

    noop() {},

    save() {
      if (this.data.saving) return
      const url = this.data.urls[this.data.idx]
      if (!url) return
      this.setData({ saving: true })
      saveImage(url, {
        original: true,
        done: () => this.setData({ saving: false }),
      })
    },
  },
})
