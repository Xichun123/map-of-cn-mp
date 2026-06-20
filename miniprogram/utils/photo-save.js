const api = require('./api')

function currentOpenid() {
  const app = getApp()
  const user = (app.getUser && app.getUser()) || (app.globalData && app.globalData.user) || wx.getStorageSync('user')
  return user && user.openid ? user.openid : ''
}

function saveDownloadedFile(tempFilePath, messages, done) {
  wx.saveImageToPhotosAlbum({
    filePath: tempFilePath,
    success: () => {
      wx.hideLoading()
      wx.showToast({ title: messages.success, icon: 'success' })
      done && done(true)
    },
    fail: () => {
      wx.hideLoading()
      wx.showToast({ title: messages.saveFail, icon: 'none' })
      done && done(false)
    },
  })
}

function downloadAndSave(url, messages, done) {
  wx.downloadFile({
    url,
    success: (r) => {
      if (r.statusCode !== 200) {
        wx.hideLoading()
        wx.showToast({ title: messages.downloadFail, icon: 'none' })
        done && done(false)
        return
      }
      saveDownloadedFile(r.tempFilePath, messages, done)
    },
    fail: () => {
      wx.hideLoading()
      wx.showToast({ title: messages.downloadFail, icon: 'none' })
      done && done(false)
    },
  })
}

function isLocalImagePath(url) {
  const s = String(url || '')
  return s.indexOf('wxfile://') === 0 || s.indexOf('http://tmp/') === 0 || !/^https?:\/\//i.test(s)
}

function withAlbumPermission(run, done) {
  wx.getSetting({
    success: (res) => {
      if (res.authSetting['scope.writePhotosAlbum'] === false) {
        wx.hideLoading()
        wx.showModal({
          title: '需要相册权限',
          content: '请在设置中允许保存到相册',
          confirmText: '去设置',
          success: (m) => {
            if (!m.confirm) {
              done && done(false)
              return
            }
            wx.openSetting({
              success: (s) => {
                if (s.authSetting['scope.writePhotosAlbum']) run()
                else done && done(false)
              },
              fail: () => done && done(false),
            })
          },
        })
      } else {
        run()
      }
    },
    fail: () => run(),
  })
}

function saveImage(imageUrl, options = {}) {
  if (!imageUrl) return
  const localImage = isLocalImagePath(imageUrl)
  const original = options.original !== false && !localImage
  const messages = {
    success: options.successText || (original ? '原图已保存' : '已保存到相册'),
    downloadFail: options.downloadFailText || (original ? '原图暂时取不到' : '这张照片暂时没取到'),
    saveFail: options.saveFailText || '这张照片暂时没存好',
  }
  const openid = currentOpenid()
  if (original && !openid) {
    wx.showToast({ title: '请先登录', icon: 'none' })
    options.done && options.done(false)
    return
  }
  const url = original ? api.originalImageUrl(imageUrl, openid) : imageUrl
  const app = getApp()
  app.vibrateShort && app.vibrateShort({ type: options.vibrateType || 'light' })
  wx.showLoading({ title: options.loadingText || (original ? '保存原图中…' : '保存中…'), mask: true })
  withAlbumPermission(() => {
    if (localImage) saveDownloadedFile(url, messages, options.done)
    else downloadAndSave(url, messages, options.done)
  }, options.done)
}

module.exports = {
  saveImage,
  isLocalImagePath,
}
