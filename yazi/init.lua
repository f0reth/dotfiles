-- ------------------------------
-- プラグイン
-- ------------------------------
-- プラグインが未インストール (ya pkg install 前) でも起動できるよう、読み込めたものだけ setup する
local function setup(name, ...)
	local ok, plugin = pcall(require, name)
	if ok then
		plugin:setup(...)
	end
end

-- 各ペインを罫線で囲む
setup("full-border")

-- ファイル一覧に Git の変更状態を表示する (yazi.toml の prepend_fetchers と併用)
setup("git")

-- ヘッダーのカレントディレクトリ表示を Starship のプロンプトにする
setup("starship")

-- ------------------------------
-- 表示
-- ------------------------------
-- linemode: サイズと更新日時を並べて表示 (今年のファイルは年を省略)
function Linemode:size_and_mtime()
	local time = math.floor(self._file.cha.mtime or 0)
	if time == 0 then
		time = ""
	elseif os.date("%Y", time) == os.date("%Y") then
		time = os.date("%m/%d %H:%M", time)
	else
		time = os.date("%Y/%m/%d", time)
	end

	local size = self._file:size()
	return string.format("%s %s", size and ya.readable_size(size) or "-", time)
end
