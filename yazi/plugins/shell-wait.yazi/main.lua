--- @since 26.8.15

-- 入力したシェルコマンドを実行し、Enter を押すまで出力を表示したままにする
return {
	entry = function()
		local value, event = ya.input {
			title = "Shell (wait):",
			pos = { "top-center", y = 2, w = 50 },
		}
		if event ~= 1 or value == "" then
			return
		end

		ya.emit("shell", {
			value .. '; echo; printf "Press Enter to return to Yazi"; read _',
			block = true,
		})
	end,
}
