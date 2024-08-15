require("gmsv")

gmsv.StartModule("Detours")
do
	function FormatLocationKey(self, Location, Key)
		local FormattedKey = isstring(Key) and Format("\"%s\"", Key) or Key

		return Format("%s[%s]", Location, FormattedKey)
	end

	function CreateDetourEnvironment(self, Replacement, Original)
		local Fenv = {} -- TODO: Extra fancy stuff for original's fenv
		package.seeall(Fenv)

		Fenv.ORIGINAL_FUNCTION = Original
		Fenv.REPLACEMENT_FUNCTION = Replacement

		return setfenv(Replacement, Fenv)
	end

	function CreateStorageTable(self, Location, Key, Replacement, Original)
		return {
			["Location"] = Location,
			["Key"] = Key,
			["Replacement"] = Replacement,
			["Original"] = Original,
			["Environment"] = self:CreateDetourEnvironment(Replacement, Original)
		}
	end

	function BackupStorageTable(self, Location, Key, Replacement, Original)
		local StorageTable = self:CreateStorageTable(Location, Key, Replacement, Original)

		self.m_Replacements[Replacement] = StorageTable
		self.m_Originals[Original] = StorageTable

		return StorageTable
	end

	function CreateFromKey(self, Location, Key, Replacement)
		if not istable(Location) or not istable(Key) then
			return FormatError("Can't find location for detouring: %s", self:FormatLocationKey(Location, Key))
		end

		local OriginalFunction = Location[Key]

		if not isfunction(OriginalFunction) then
			return FormatError("Can't find function for detouring: %s", self:FormatLocationKey(Location, Key))
		end

		local StorageTable = self:BackupStorageTable(Location, Key, Replacement, OriginalFunction)

		Location[Key] = Replacement

		return StorageTable
	end

	function RestoreFromKey(self, Location, Key)
		if not istable(Location) or not istable(Key) then
			return FormatError("Can't find location for restoring: %s", self:FormatLocationKey(Location, Key))
		end

		local Replacement = Location[Key]

		if not isfunction(Replacement) then
			return FormatError("Can't find replacement for restoring: %s", self:FormatLocationKey(Location, Key))
		end

		local StorageTable = self.m_Replacements[Replacement]

		if not istable(StorageTable) then
			return FormatError("Can't find storage table for restoring: %s", self:FormatLocationKey(Location, Key))
		end

		Location[Key] = StorageTable.Original
	end

	function DetourGeneric(self, Lookup, Replacement)
		local Existing, Key, Location = string.ToIndex(Lookup)

		local ReplacementStorageTable = self.m_Replacements[Existing]

		if istable(ReplacementStorageTable) then
			MsgDev("Attempted to re-detour %s", self:FormatLocationKey(Location, Key))
			return ReplacementStorageTable
		end

		return self:CreateFromKey(Location, Key, Replacement)
	end

	function RestoreGeneric(self, Lookup)
		local Existing, Key, Location = string.ToIndex(Lookup)

		local OriginalStorageTable = self.m_Originals[Existing]

		if istable(OriginalStorageTable) then
			MsgDev("Attempted to re-restore %s", self:FormatLocationKey(Location, Key))
			return
		end

		self:RestoreFromKey(Location, Key)
	end

	function OnEnabled(self)
		if not istable(self.m_Replacements) or not istable(self.m_Originals) then
			self.m_Replacements = {}
			self.m_Originals = {}
		end

		self:GetConfig():SetValue("Togglable", false)
	end

	function OnDisabled(self)
		self:SetEnabled(true)
	end
end
gmsv.EndModule()
