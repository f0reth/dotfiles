--- @since 26.8.15

-- 入力したシェルコマンドを実行し、キーを押すまで出力を表示したままにする
-- Yazi の shell は Unix では sh、Windows では cmd.exe で実行されるため、待機部分を書き分ける
local WAIT = {
	unix = '; echo; printf "Press Enter to return to Yazi"; read _',
	-- pause の日本語メッセージを消して英語に揃える (set /p だと空入力で終了コードが 1 になる)
	windows = " & echo. & echo Press any key to return to Yazi & pause > nul",
}

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
			value .. (WAIT[ya.target_family()] or WAIT.unix),
			block = true,
		})
	end,
}
