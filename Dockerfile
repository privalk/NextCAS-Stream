# 1. 使用官方的 Node.js 镜像作为基础镜像
FROM node:18-alpine AS build

# 2. 设置工作目录
WORKDIR /app

# 3. 复制 package.json 和 package-lock.json
COPY package*.json ./

# 4. 安装项目依赖
RUN npm install

# 5. 复制项目的所有文件到工作目录
COPY . .

# 6. 构建项目（生成静态文件）
RUN npm run build

# 7. 使用轻量级的 nginx 镜像来部署静态文件
FROM nginx:alpine

# 8. 复制构建的静态文件到 nginx 目录
COPY --from=build /app/dist /usr/share/nginx/html

# 9. 复制自定义的 nginx 配置文件（可选）
# COPY nginx.conf /etc/nginx/nginx.conf

# 10. 暴露端口
EXPOSE 80

# 11. 启动 nginx
CMD ["nginx", "-g", "daemon off;"]
