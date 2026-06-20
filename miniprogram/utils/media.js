const PICKER_BATCH_LIMIT = 9

function chooseImageBatch(count) {
  return new Promise((resolve, reject) => {
    wx.chooseMedia({
      count,
      mediaType: ['image'],
      sizeType: ['original'],
      sourceType: ['album', 'camera'],
      success: (res) => {
        const paths = (res.tempFiles || []).map((f) => f.tempFilePath).filter(Boolean)
        resolve(paths)
      },
      fail: (err) => {
        const msg = String((err && err.errMsg) || '').toLowerCase()
        if (msg.includes('cancel')) {
          resolve([])
          return
        }
        reject(err)
      },
    })
  })
}

function confirmMore(total) {
  return new Promise((resolve) => {
    wx.showModal({
      title: '继续选择照片',
      content: `已经选了 ${total} 张，还要继续选吗？`,
      confirmText: '继续选',
      cancelText: '完成',
      success: (res) => resolve(!!res.confirm),
      fail: () => resolve(false),
    })
  })
}

async function chooseImagesMany(limit = 99) {
  const max = Math.max(1, Number(limit) || 1)
  const paths = []
  while (paths.length < max) {
    const count = Math.min(PICKER_BATCH_LIMIT, max - paths.length)
    const batch = await chooseImageBatch(count)
    if (!batch.length) break
    paths.push(...batch)
    if (batch.length < count || paths.length >= max) break
    const keepGoing = await confirmMore(paths.length)
    if (!keepGoing) break
  }
  return paths
}

module.exports = {
  chooseImagesMany,
}
