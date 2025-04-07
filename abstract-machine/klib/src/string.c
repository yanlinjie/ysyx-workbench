#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
  size_t len = 0;
  while (*s++) len++;
  return len;
  // panic("Not implemented");
}

char *strcpy(char *dst, const char *src) {
  // panic("Not implemented");
    char *original_dst = dst;  // 保存目标字符串的起始地址，最终返回给调用者

    // 遍历源字符串，逐个字符复制到目标字符串
    while (*src) {  // 如果 src 当前指向的字符不是 '\0'
        *dst = *src;  // 将 src 的字符复制到 dst
        dst++;         // dst 指针向后移动
        src++;         // src 指针向后移动
    }

    // 复制完后，将 '\0' 也复制到目标字符串的结尾
    *dst = '\0';

    return original_dst;  // 返回目标字符串的起始地址

}

char *strncpy(char *dst, const char *src, size_t n) {
  char *original_dst = dst;

  // 拷贝 src 中的字符直到 '\0' 或达到 n 个字符
  size_t i = 0;
  while (i < n && src[i] != '\0') {
    dst[i] = src[i];
    i++;
  }

  // 如果 src 长度小于 n，用 '\0' 填充剩余空间
  while (i < n) {
    dst[i] = '\0';
    i++;
  }

  return original_dst;
  // panic("Not implemented");
}

char *strcat(char *dst, const char *src) {
  // panic("Not implemented");
    char *original_dst = dst;  // 保存目标字符串的起始地址

    // 找到目标字符串的结尾，直到遇到 '\0'
    while (*dst) {
        dst++;  // dst 指针移动到字符串末尾
    }

    // 从目标字符串末尾开始，复制源字符串
    while (*src) {
        *dst = *src;  // 将 src 的字符复制到 dst
        dst++;         // dst 指针向后移动
        src++;         // src 指针向后移动
    }

    // 添加 '\0' 到目标字符串的末尾
    *dst = '\0';

    return original_dst;  // 返回目标字符串的起始地址
}

int strcmp(const char *s1, const char *s2) {
    // 比较两个字符串的字符
    while (*s1 && *s2) {  // 直到其中一个字符串结束
        if (*s1 != *s2) {  // 如果当前字符不同
            return (unsigned char)*s1 - (unsigned char)*s2;
        }
        s1++;
        s2++;
    }

    // 如果两个字符串长度不同，返回它们的差异
    return (unsigned char)*s1 - (unsigned char)*s2;
}

int strncmp(const char *s1, const char *s2, size_t n) {
  size_t i = 0;

  while (i < n) {
    if (s1[i] != s2[i]) {
      return (unsigned char)s1[i] - (unsigned char)s2[i];
    }
    // 遇到字符串结尾则结束
    if (s1[i] == '\0') {
      return 0;
    }
    i++;
  }

  return 0; // 前 n 个字符都相同
  // panic("Not implemented");
}

void *memset(void *s, int c, size_t n) {
  // panic("Not implemented");
    unsigned char *ptr = s;  // 将 void* 转换为 unsigned char*，方便逐字节操作
    unsigned char value = (unsigned char)c;  // 将 c 转换为 unsigned char，确保按字节设置

    // 循环 n 次，逐个字节设置值
    for (size_t i = 0; i < n; i++) {
        ptr[i] = value;  // 将每个字节设置为指定值
    }

    return s;  // 返回原始指针
}

  void *memmove(void *dst, const void *src, size_t n) {
    unsigned char *d = dst;
    const unsigned char *s = src;
  
    if (d == s || n == 0) return dst;
  
    if (d < s) {
      // 正向复制（从前往后）
      for (size_t i = 0; i < n; i++) {
        d[i] = s[i];
      }
    } else {
      // 反向复制（从后往前）以防止重叠覆盖
      for (size_t i = n; i != 0; i--) {
        d[i - 1] = s[i - 1];
      }
    }
  
    return dst;
  }
  


void *memcpy(void *out, const void *in, size_t n) {
  unsigned char *d = out;
  const unsigned char *s = in;
  for (size_t i = 0; i < n; i++) {
    d[i] = s[i];
  }
  return out;
  // panic("Not implemented");
}

int memcmp(const void *s1, const void *s2, size_t n) {
  // panic("Not implemented");
    const unsigned char *ptr1 = s1;
    const unsigned char *ptr2 = s2;

    // 逐字节比较两个内存块
    for (size_t i = 0; i < n; i++) {
        if (ptr1[i] != ptr2[i]) {
            return ptr1[i] - ptr2[i];  // 返回第一个不同字节的差值
        }
    }

    return 0;  // 如果所有字节都相等，返回 0
}

#endif
