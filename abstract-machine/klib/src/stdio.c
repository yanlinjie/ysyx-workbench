#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

//  实现 printf：调用 sprintf + 输出
int printf(const char *fmt, ...) {
  char buf[1024];
  va_list args;
  va_start(args, fmt);
  int len = vsprintf(buf, fmt, args); 
  va_end(args);

  for (int i = 0; i < len; i++) {
    putch(buf[i]);
  }
  return len;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  int count = 0;

  for (const char *p = fmt; *p != '\0'; p++) {
    if (*p == '%' && *(p + 1) != '\0') {
      p++;

      // -------- 解析格式宽度和补零 --------
      int zero_pad = 0;
      int width = 0;

      if (*p == '0') {
        zero_pad = 1;
        p++;
        while (*p >= '0' && *p <= '9') {
          width = width * 10 + (*p - '0');
          p++;
        }
      }

      int long_flag = 0;
      if (*p == 'l') {
        long_flag = 1;
        p++;
      }

      // -------- 实际格式类型 --------
      if (*p == 'd') {
        long long val = long_flag ? va_arg(ap, long) : va_arg(ap, int);
        char temp[32];
        int i = 0;

        int is_negative = 0;
        if (val < 0) {
          is_negative = 1;
          val = -val;
        }

        do {
          temp[i++] = val % 10 + '0';
          val /= 10;
        } while (val > 0);

        if (is_negative) temp[i++] = '-';
        temp[i] = '\0';

        for (int l = 0, r = i - 1; l < r; l++, r--) {
          char t = temp[l]; temp[l] = temp[r]; temp[r] = t;
        }

        int len = i;
        int pad_len = (width > len) ? width - len : 0;
        char pad_char = zero_pad ? '0' : ' ';
        for (int j = 0; j < pad_len; j++) out[count++] = pad_char;
        for (int j = 0; j < len; j++) out[count++] = temp[j];
      }

      else if (*p == 'x') {
        unsigned long long val = long_flag ? va_arg(ap, unsigned long) : va_arg(ap, unsigned int);
        char temp[32];
        int i = 0;

        do {
          int digit = val % 16;
          temp[i++] = digit < 10 ? ('0' + digit) : ('a' + digit - 10);
          val /= 16;
        } while (val > 0);

        temp[i] = '\0';

        for (int l = 0, r = i - 1; l < r; l++, r--) {
          char t = temp[l]; temp[l] = temp[r]; temp[r] = t;
        }

        int len = i;
        int pad_len = (width > len) ? width - len : 0;
        char pad_char = zero_pad ? '0' : ' ';
        for (int j = 0; j < pad_len; j++) out[count++] = pad_char;
        for (int j = 0; j < len; j++) out[count++] = temp[j];
      }

      else if (*p == 's') {
        char *str = va_arg(ap, char *);
        while (*str) out[count++] = *str++;
      }

      else if (*p == 'c') {
        char ch = (char)va_arg(ap, int);
        out[count++] = ch;
      }

      else {
        out[count++] = '%';
        out[count++] = *p;
      }

    } else {
      out[count++] = *p;
    }
  }

  out[count] = '\0';
  return count;
}




//  实现 sprintf
int sprintf(char *out, const char *fmt, ...) {
  va_list args;
  va_start(args, fmt);
  int len = vsprintf(out, fmt, args);
  va_end(args);
  return len;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

#endif
