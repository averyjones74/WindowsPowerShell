<#
.Synopsis
    Copies the currently selected text in the current file with colorization
.Description
    Copies the currently selected text in the current file with colorization.
    This allows for a user to paste colorized scripts into Word or Outlook
.Example
    Copy-Colored 
#>

function Copy-Colorized ()
{
    if (-not $psISE.CurrentFile)
    {
        return
    }
    
    function Colorize
    {
        # colorize a script file or function

        param([string]$Text, [int]$Start = -1, [int]$End = -1)
        trap { break }
        $box = New-Object Windows.Forms.RichTextBox    
        $box.Font = New-Object Drawing.Font $psISE.Options.FontName, $psISE.Options.FontSize
        $box.Text = $Text

        # Now parse the text and report any errors...
        $parse_errs = $null
        $tokens = [System.Management.Automation.PSParser]::Tokenize($box.Text, [ref] $parse_errs)

        if ($parse_errs)
        {
            $parse_errs
            return
        }

        # iterate over the tokens an set the colors appropriately...
        foreach ($t in $tokens)
        {
            $box.Select($t.start, $t.length)
            $color = $psISE.Options.DefaultOptions.TokenColors[$t.Type]
            if ($color)
            {
                $box.selectioncolor = [Drawing.Color]::FromArgb($color.A, $color.R, $color.G, $color.B)
            }
        }
        if ($start -eq -1 -and $end -eq -1)
        {
            $box.Select(0,$box.Text.Length)
        }
        else
        {
            $box.Select($start, $end)
        }

        $box.Copy()
    }

    $editor = $psISE.CurrentFile.Editor
    $text = $editor.Text -replace '\r\n', "`n"
    if (-not $editor.SelectedText)
    {
        $selection = ($editor.Text -replace '\r\n', "`n")
    }
    else
    {
        $selection = ($editor.SelectedText -replace '\r\n', "`n")
    }

    Colorize $text $text.IndexOf(($selection -replace '\r\n', "`n")) $selection.Length
}

# SIG # Begin signature block
# MIINIQYJKoZIhvcNAQcCoIINEjCCDQ4CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUmNMF6igAysqBvd8RckLJusjq
# HyqgggpWMIIE9TCCA92gAwIBAgIQJNJNfU2gAP3HGaji2H4jXTANBgkqhkiG9w0B
# AQsFADB/MQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRp
# b24xHzAdBgNVBAsTFlN5bWFudGVjIFRydXN0IE5ldHdvcmsxMDAuBgNVBAMTJ1N5
# bWFudGVjIENsYXNzIDMgU0hBMjU2IENvZGUgU2lnbmluZyBDQTAeFw0xNTA2MjQw
# MDAwMDBaFw0xODA3MjMyMzU5NTlaMIGHMQswCQYDVQQGEwJVUzEWMBQGA1UECBMN
# TWFzc2FjaHVzZXR0czEQMA4GA1UEBxMHTWlsZm9yZDEbMBkGA1UEChQSV2F0ZXJz
# IENvcnBvcmF0aW9uMRQwEgYDVQQLFAtJbmZvcm1hdGljczEbMBkGA1UEAxQSV2F0
# ZXJzIENvcnBvcmF0aW9uMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
# s00KvxoIZfX/ueMwE9AS1gx+VrG8n4raLJA4QPXnSW+4Ae3gOPoiHwjYD+RW7+Db
# 5y5PMADShoLkJWcsoOB9egN/tUnV2Zlz2/3L0f5KAN5XUvym2vjJBXbK484BMnd8
# LyOR9U0jAiY3tFJZvQBh8NVmBFvTZR20osM1r1Z2cGadeiUkKxGO0JETiWZBK4au
# mlHe7PXiWhkyhi+hLZdnXhLQPydAzd5X6vcQum3C3rCDE4PPD8/1UQz1A2G8BuzI
# oT5Ha6ES0x113qTW4sMBOfwxnhv60SiICHxZwltbEt26HPw44q65r5LncBbHEiTd
# 7lGEl/hyPq1+1vJxoiLW3wIDAQABo4IBYjCCAV4wCQYDVR0TBAIwADAOBgNVHQ8B
# Af8EBAMCB4AwKwYDVR0fBCQwIjAgoB6gHIYaaHR0cDovL3N2LnN5bWNiLmNvbS9z
# di5jcmwwZgYDVR0gBF8wXTBbBgtghkgBhvhFAQcXAzBMMCMGCCsGAQUFBwIBFhdo
# dHRwczovL2Quc3ltY2IuY29tL2NwczAlBggrBgEFBQcCAjAZDBdodHRwczovL2Qu
# c3ltY2IuY29tL3JwYTATBgNVHSUEDDAKBggrBgEFBQcDAzBXBggrBgEFBQcBAQRL
# MEkwHwYIKwYBBQUHMAGGE2h0dHA6Ly9zdi5zeW1jZC5jb20wJgYIKwYBBQUHMAKG
# Gmh0dHA6Ly9zdi5zeW1jYi5jb20vc3YuY3J0MB8GA1UdIwQYMBaAFJY7U/B5M5ev
# fYPvLivMyreGHnJmMB0GA1UdDgQWBBTqEzkwwDqoq15Zc9xJrYV6VUbw+zANBgkq
# hkiG9w0BAQsFAAOCAQEAdgdVLBPA0mAxL3onwAkQcY0j+9i05R+aIaeFOhuzFyTI
# /CQMx9Oec2irX9ZjMS/MADj3G2XQTV/RImB6/viZjZ520iF8wlfEaMprmCYJjfJi
# OHjym9z16Na9ruqJ4t4+GDldnMvYdVSmhg2v+Ff6q3CYziMhi+7ggV9Q+6TbALxn
# u2T6cLHmHyF0DTmCApos9CgTHncyJIPhYCl91CdFdpgO4raV5ZACIa17Elt18/zl
# oZB4Yz2Qokh6ZuRGv2PsvkDjL9ASeR/y3i74sVYecqUPqdl+eMyfh8QM1ebJM1iA
# CI7XqBhGwbSs7+4QJGfeG0K44csQegxFRlBTj29rIjCCBVkwggRBoAMCAQICED14
# 1/l2SWCyYX308B7KhiowDQYJKoZIhvcNAQELBQAwgcoxCzAJBgNVBAYTAlVTMRcw
# FQYDVQQKEw5WZXJpU2lnbiwgSW5jLjEfMB0GA1UECxMWVmVyaVNpZ24gVHJ1c3Qg
# TmV0d29yazE6MDgGA1UECxMxKGMpIDIwMDYgVmVyaVNpZ24sIEluYy4gLSBGb3Ig
# YXV0aG9yaXplZCB1c2Ugb25seTFFMEMGA1UEAxM8VmVyaVNpZ24gQ2xhc3MgMyBQ
# dWJsaWMgUHJpbWFyeSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eSAtIEc1MB4XDTEz
# MTIxMDAwMDAwMFoXDTIzMTIwOTIzNTk1OVowfzELMAkGA1UEBhMCVVMxHTAbBgNV
# BAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMR8wHQYDVQQLExZTeW1hbnRlYyBUcnVz
# dCBOZXR3b3JrMTAwLgYDVQQDEydTeW1hbnRlYyBDbGFzcyAzIFNIQTI1NiBDb2Rl
# IFNpZ25pbmcgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCXgx4A
# Fq8ssdIIxNdok1FgHnH24ke021hNI2JqtL9aG1H3ow0Yd2i72DarLyFQ2p7z518n
# TgvCl8gJcJOp2lwNTqQNkaC07BTOkXJULs6j20TpUhs/QTzKSuSqwOg5q1PMIdDM
# z3+b5sLMWGqCFe49Ns8cxZcHJI7xe74xLT1u3LWZQp9LYZVfHHDuF33bi+VhiXjH
# aBuvEXgamK7EVUdT2bMy1qEORkDFl5KK0VOnmVuFNVfT6pNiYSAKxzB3JBFNYoO2
# untogjHuZcrf+dWNsjXcjCtvanJcYISc8gyUXsBWUgBIzNP4pX3eL9cT5DiohNVG
# uBOGwhud6lo43ZvbAgMBAAGjggGDMIIBfzAvBggrBgEFBQcBAQQjMCEwHwYIKwYB
# BQUHMAGGE2h0dHA6Ly9zMi5zeW1jYi5jb20wEgYDVR0TAQH/BAgwBgEB/wIBADBs
# BgNVHSAEZTBjMGEGC2CGSAGG+EUBBxcDMFIwJgYIKwYBBQUHAgEWGmh0dHA6Ly93
# d3cuc3ltYXV0aC5jb20vY3BzMCgGCCsGAQUFBwICMBwaGmh0dHA6Ly93d3cuc3lt
# YXV0aC5jb20vcnBhMDAGA1UdHwQpMCcwJaAjoCGGH2h0dHA6Ly9zMS5zeW1jYi5j
# b20vcGNhMy1nNS5jcmwwHQYDVR0lBBYwFAYIKwYBBQUHAwIGCCsGAQUFBwMDMA4G
# A1UdDwEB/wQEAwIBBjApBgNVHREEIjAgpB4wHDEaMBgGA1UEAxMRU3ltYW50ZWNQ
# S0ktMS01NjcwHQYDVR0OBBYEFJY7U/B5M5evfYPvLivMyreGHnJmMB8GA1UdIwQY
# MBaAFH/TZafC3ey78DAJ80M5+gKvMzEzMA0GCSqGSIb3DQEBCwUAA4IBAQAThRoe
# aak396C9pK9+HWFT/p2MXgymdR54FyPd/ewaA1U5+3GVx2Vap44w0kRaYdtwb9oh
# BcIuc7pJ8dGT/l3JzV4D4ImeP3Qe1/c4i6nWz7s1LzNYqJJW0chNO4LmeYQW/Ciw
# sUfzHaI+7ofZpn+kVqU/rYQuKd58vKiqoz0EAeq6k6IOUCIpF0yH5DoRX9akJYmb
# BWsvtMkBTCd7C6wZBSKgYBU/2sn7TUyP+3Jnd/0nlMe6NQ6ISf6N/SivShK9DbOX
# Bd5EDBX6NisD3MFQAfGhEV0U5eK9J0tUviuEXg+mw3QFCu+Xw4kisR93873NQ9Tx
# TKk/tYuEr2Ty0BQhMYICNTCCAjECAQEwgZMwfzELMAkGA1UEBhMCVVMxHTAbBgNV
# BAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMR8wHQYDVQQLExZTeW1hbnRlYyBUcnVz
# dCBOZXR3b3JrMTAwLgYDVQQDEydTeW1hbnRlYyBDbGFzcyAzIFNIQTI1NiBDb2Rl
# IFNpZ25pbmcgQ0ECECTSTX1NoAD9xxmo4th+I10wCQYFKw4DAhoFAKB4MBgGCisG
# AQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFHwn
# h9BI1cZEOy8R9BMjq05mLEwgMA0GCSqGSIb3DQEBAQUABIIBAKiClyqkKKNghNwt
# WLGrpZy8DgwvvrXMWAI68zXhs6Q8KQN7TSu1pOWMHqsFojX0N3XcuC0ts3smWy1Z
# cpXQUu3KwFTfHYwKc2iBsh8SCHyk82v2SLnCfAnHp6yQXniwIPsMzVQIijBofDcm
# B25LPUko9KtalXTuWkHykHImKx53bMW99bvDc6LRlObcxvw+xmCkey1qlZoYX105
# sS0Jr1R0kfA/y1O0hDriaylwJbRRpkB5AkZ5PuwIJI43bwVToaPD4NOocrzVRlkE
# UB+R+dvxTKb/dogaLdRiMbHVLw5FM0iyvrCnGrbQFL7IeRllXqLwF2E7645E5PGp
# vIOGaAo=
# SIG # End signature block
