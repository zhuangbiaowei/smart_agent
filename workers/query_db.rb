SmartPrompt.define_worker :query_db do
  use "SiliconFlow"
  model "Pro/deepseek-ai/DeepSeek-V3"
  sys_msg "你是一个聪明的智能助手，能够调用工具获取数据库表结构信息，并生产正确的SQL语句，从而回答用户的问题"
  prompt params[:text]
  send_msg
end
