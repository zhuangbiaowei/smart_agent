SmartPrompt.define_worker :get_code do
  use "deepseek"
  model "deepseek-chat"
  sys_msg "You are a helpful programmer."
  prompt :generate_code, {
    name: params["name"],
    description: params["description"],
    input_params_type: params["input_params_type"],
    output_value_type: params["output_value_type"],
  }
  code_text = send_msg
  if code_text.include?("Failed to call LLM after")
    code_text
  else
    prompt :get_code, { code_text: code_text }
    code = send_msg
    if code.include?("```ruby\n")
      code = code.gsub("```ruby\n", "")
    end
    if code.include?("```")
      code = code.gsub("```", "")
    end
    code
  end
end
