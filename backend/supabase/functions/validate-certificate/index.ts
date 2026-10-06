import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface CertificateValidationRequest {
  certificateId: string
  certificateName: string
  certificateUrl?: string
  providerId?: string
  issueDate?: string
  fileUrl?: string
}

interface ValidationResult {
  isValid: boolean
  confidence: number
  method: string
  extractedSkills: Record<string, number>
  validationDetails: any
  errors?: string[]
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { certificateId, certificateName, certificateUrl, providerId, issueDate, fileUrl }: CertificateValidationRequest = await req.json()

    console.log('Validating certificate:', { certificateId, certificateName, providerId })

    // Get provider information
    const { data: provider } = await supabase
      .from('certification_providers')
      .select('*')
      .eq('id', providerId)
      .single()

    if (!provider) {
      throw new Error('Provider not found')
    }

    let validationResult: ValidationResult = {
      isValid: false,
      confidence: 0,
      method: 'unknown',
      extractedSkills: {},
      validationDetails: {}
    }

    // Choose validation method based on provider
    switch (provider.validation_method) {
      case 'api':
        validationResult = await validateViaAPI(supabase, provider, certificateId, certificateUrl)
        break
      case 'pattern':
        validationResult = await validateViaPattern(provider, certificateName, certificateId, certificateUrl)
        break
      case 'ocr':
        validationResult = await validateViaOCR(fileUrl, provider)
        break
      default:
        validationResult = await validateViaPattern(provider, certificateName, certificateId, certificateUrl)
    }

    // Extract skills from certificate name and content
    const extractedSkills = await extractSkillsFromCertificate(supabase, certificateName, validationResult.validationDetails)
    validationResult.extractedSkills = extractedSkills

    // Determine final validation status
    const finalStatus = determineFinalStatus(validationResult, provider)

    return new Response(
      JSON.stringify({
        success: true,
        validation: {
          ...validationResult,
          status: finalStatus,
          providerId: provider.id,
          providerName: provider.name,
          trustScore: provider.trust_score
        }
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )

  } catch (error: any) {
    console.error('Certificate validation error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : String(error)
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      },
    )
  }
})

async function validateViaAPI(supabase: any, provider: any, certificateId: string, certificateUrl?: string): Promise<ValidationResult> {
  console.log('Validating via API for provider:', provider.short_code)

  try {
    switch (provider.short_code) {
      case 'NPTEL':
        return await validateNPTEL(certificateId, certificateUrl)
      case 'SWAYAM':
        return await validateSWAYAM(certificateId, certificateUrl)
      case 'COURSERA':
        return await validateCoursera(certificateId, certificateUrl)
      case 'EDX':
        return await validateEdX(certificateId, certificateUrl)
      case 'GCP':
        return await validateGCP(certificateId, certificateUrl)
      case 'AWS':
        return await validateAWS(certificateId, certificateUrl)
      case 'AZURE':
        return await validateAzure(certificateId, certificateUrl)
      case 'CareerBridge':
        return await validateCareerBridge(supabase, certificateId, certificateUrl)
      default:
        return await validateGenericAPI(provider, certificateId, certificateUrl)
    }
  } catch (error: any) {
    console.error('API validation failed:', error)
    return {
      isValid: false,
      confidence: 0,
      method: 'api_failed',
      extractedSkills: {},
      validationDetails: { error: error instanceof Error ? error.message : String(error) }
    }
  }
}

async function validateNPTEL(certificateId: string, certificateUrl?: string): Promise<ValidationResult> {
  // NPTEL certificate validation logic
  if (!certificateId || certificateId.length < 8) {
    return {
      isValid: false,
      confidence: 0,
      method: 'nptel_api',
      extractedSkills: {},
      validationDetails: { error: 'Invalid NPTEL certificate ID format' }
    }
  }

  // Simulate NPTEL API call (replace with actual API when available)
  // Support newer format like NPTEL25CS103S862900461
  const isValidFormat = /^NPTEL\d{2}[A-Z0-9]{2,10}\d{5,15}$/.test(certificateId.toUpperCase())

  if (certificateUrl) {
    const isValidUrl = certificateUrl.includes('nptel.ac.in') && certificateUrl.includes(certificateId)
    return {
      isValid: isValidFormat && isValidUrl,
      confidence: isValidFormat && isValidUrl ? 95 : 20,
      method: 'nptel_api',
      extractedSkills: {},
      validationDetails: {
        formatValid: isValidFormat,
        urlValid: isValidUrl,
        certificateUrl
      }
    }
  }

  return {
    isValid: isValidFormat,
    confidence: isValidFormat ? 80 : 10,
    method: 'nptel_pattern',
    extractedSkills: {},
    validationDetails: { formatValid: isValidFormat }
  }
}

async function validateSWAYAM(certificateId: string, certificateUrl?: string): Promise<ValidationResult> {
  // SWAYAM certificate validation
  const isValidFormat = /^[A-Z0-9]{10,20}$/.test(certificateId)
  const isValidUrl = certificateUrl ? certificateUrl.includes('swayam.gov.in') : false

  return {
    isValid: isValidFormat && (certificateUrl ? isValidUrl : true),
    confidence: isValidFormat ? (certificateUrl && isValidUrl ? 90 : 70) : 10,
    method: 'swayam_pattern',
    extractedSkills: {},
    validationDetails: {
      formatValid: isValidFormat,
      urlValid: isValidUrl
    }
  }
}

async function validateCoursera(certificateId: string, certificateUrl?: string): Promise<ValidationResult> {
  // Coursera certificate validation
  const isValidUrl = certificateUrl ?
    (certificateUrl.includes('coursera.org/verify/') || certificateUrl.includes('coursera.org/account/accomplishments/')) :
    false

  if (certificateUrl && isValidUrl) {
    try {
      // Try to fetch the certificate page to verify it exists
      const response = await fetch(certificateUrl, { method: 'GET' })
      const exists = response.status === 200

      return {
        isValid: exists,
        confidence: exists ? 85 : 20,
        method: 'coursera_url_check',
        extractedSkills: {},
        validationDetails: {
          urlExists: exists,
          statusCode: response.status
        }
      }
    } catch (error) {
      return {
        isValid: false,
        confidence: 10,
        method: 'coursera_url_failed',
        extractedSkills: {},
        validationDetails: { error: error.message }
      }
    }
  }

  return {
    isValid: false,
    confidence: 0,
    method: 'coursera_insufficient_data',
    extractedSkills: {},
    validationDetails: { error: 'Certificate URL required for Coursera validation' }
  }
}

async function validateEdX(certificateId: string, certificateUrl?: string): Promise<ValidationResult> {
  // edX certificate validation
  const isValidUrl = certificateUrl ? certificateUrl.includes('courses.edx.org/certificates/') : false

  return {
    isValid: isValidUrl,
    confidence: isValidUrl ? 80 : 10,
    method: 'edx_url_pattern',
    extractedSkills: {},
    validationDetails: { urlValid: isValidUrl }
  }
}

async function validateGCP(certificateId: string, certificateUrl?: string): Promise<ValidationResult> {
  // Google Cloud Platform certificate validation
  const isValidUrl = certificateUrl ?
    (certificateUrl.includes('google.com/') && certificateUrl.includes('credential')) :
    false

  return {
    isValid: isValidUrl,
    confidence: isValidUrl ? 90 : 30,
    method: 'gcp_url_pattern',
    extractedSkills: {},
    validationDetails: { urlValid: isValidUrl }
  }
}

async function validateAWS(certificateId: string, certificateUrl?: string): Promise<ValidationResult> {
  // AWS certificate validation
  const isValidUrl = certificateUrl ?
    (certificateUrl.includes('aws.amazon.com/verification') || certificateUrl.includes('credly.com')) :
    false

  return {
    isValid: isValidUrl,
    confidence: isValidUrl ? 90 : 30,
    method: 'aws_url_pattern',
    extractedSkills: {},
    validationDetails: { urlValid: isValidUrl }
  }
}

async function validateAzure(certificateId: string, certificateUrl?: string): Promise<ValidationResult> {
  // Microsoft Azure certificate validation
  const isValidUrl = certificateUrl ?
    (certificateUrl.includes('microsoft.com') || certificateUrl.includes('credly.com')) :
    false

  return {
    isValid: isValidUrl,
    confidence: isValidUrl ? 90 : 30,
    method: 'azure_url_pattern',
    extractedSkills: {},
    validationDetails: { urlValid: isValidUrl }
  }
}

async function validateGenericAPI(provider: any, certificateId: string, certificateUrl?: string): Promise<ValidationResult> {
  // Generic API validation for other providers
  if (provider.api_endpoint) {
    try {
      const response = await fetch(`${provider.api_endpoint}/verify/${certificateId}`)
      const data = await response.json()

      return {
        isValid: data.valid || false,
        confidence: data.confidence || 50,
        method: 'generic_api',
        extractedSkills: {},
        validationDetails: data
      }
    } catch (error) {
      return {
        isValid: false,
        confidence: 0,
        method: 'generic_api_failed',
        extractedSkills: {},
        validationDetails: { error: error.message }
      }
    }
  }

  return {
    isValid: false,
    confidence: 0,
    method: 'no_api_endpoint',
    extractedSkills: {},
    validationDetails: { error: 'No API endpoint configured' }
  }
}

async function validateViaPattern(provider: any, certificateName: string, certificateId: string, certificateUrl?: string): Promise<ValidationResult> {
  console.log('Validating via pattern matching')

  let confidence = 0
  const validationDetails: any = {}

  // Check certificate name patterns
  if (certificateName) {
    const nameScore = calculateNameScore(certificateName, provider.short_code)
    confidence += nameScore
    validationDetails.nameScore = nameScore
  }

  // Check certificate ID patterns
  if (certificateId) {
    const idScore = calculateIdScore(certificateId, provider.short_code)
    confidence += idScore
    validationDetails.idScore = idScore
  }

  // Check URL patterns
  if (certificateUrl) {
    const urlScore = calculateUrlScore(certificateUrl, provider.website_url)
    confidence += urlScore
    validationDetails.urlScore = urlScore
  }

  // Normalize confidence to 0-100
  confidence = Math.min(confidence, 100)

  return {
    isValid: confidence >= 60,
    confidence,
    method: 'pattern_matching',
    extractedSkills: {},
    validationDetails
  }
}

function calculateNameScore(certificateName: string, providerCode: string): number {
  const name = certificateName.toLowerCase()
  let score = 0

  // Provider-specific patterns
  switch (providerCode) {
    case 'UDEMY':
      if (name.includes('udemy') || name.includes('certificate of completion')) score += 30
      break
    case 'CODECADEMY':
      if (name.includes('codecademy') || name.includes('skill path')) score += 30
      break
    case 'FREECODECAMP':
      if (name.includes('freecodecamp') || name.includes('certification')) score += 30
      break
    case 'HACKERRANK':
      if (name.includes('hackerrank') || name.includes('skill assessment')) score += 30
      break
  }

  // Generic certificate indicators
  if (name.includes('certificate') || name.includes('certification')) score += 10
  if (name.includes('completion') || name.includes('achievement')) score += 10
  if (name.includes('course') || name.includes('program')) score += 5

  return Math.min(score, 50)
}

function calculateIdScore(certificateId: string, providerCode: string): number {
  let score = 0

  // Basic format checks
  if (certificateId.length >= 8) score += 10
  if (/[A-Z]/.test(certificateId)) score += 5
  if (/[0-9]/.test(certificateId)) score += 5

  // Provider-specific patterns
  switch (providerCode) {
    case 'UDEMY':
      if (/UC-[A-Z0-9]{8}/.test(certificateId)) score += 20
      break
    case 'COURSERA':
      if (/[A-Z0-9]{12,}/.test(certificateId)) score += 20
      break
  }

  return Math.min(score, 30)
}

function calculateUrlScore(certificateUrl: string, providerWebsite: string): number {
  let score = 0

  try {
    const url = new URL(certificateUrl)
    const providerDomain = new URL(providerWebsite).hostname

    if (url.hostname.includes(providerDomain) || providerDomain.includes(url.hostname)) {
      score += 20
    }

    if (url.protocol === 'https:') score += 5
    if (url.pathname.includes('certificate') || url.pathname.includes('verify')) score += 5

  } catch (error) {
    // Invalid URL
    return 0
  }

  return Math.min(score, 30)
}

async function validateViaOCR(fileUrl: string, provider: any): Promise<ValidationResult> {
  // OCR validation would require additional services like Google Vision API
  // For now, return a basic implementation
  console.log('OCR validation not yet implemented')

  return {
    isValid: false,
    confidence: 0,
    method: 'ocr_not_implemented',
    extractedSkills: {},
    validationDetails: { error: 'OCR validation not yet implemented' }
  }
}

async function extractSkillsFromCertificate(supabase: any, certificateName: string, validationDetails: any): Promise<Record<string, number>> {
  const extractedSkills: Record<string, number> = {}

  // Get all skills from database
  const { data: skills } = await supabase
    .from('skills_database')
    .select('name, keywords, base_points')

  if (!skills) return extractedSkills

  const certificateText = certificateName.toLowerCase()

  // Match skills based on keywords
  for (const skill of skills) {
    let matchScore = 0

    // Check if skill name is in certificate
    if (certificateText.includes(skill.name.toLowerCase())) {
      matchScore = 90
    } else {
      // Check keywords
      for (const keyword of skill.keywords || []) {
        if (certificateText.includes(keyword.toLowerCase())) {
          matchScore = Math.max(matchScore, 70)
        }
      }
    }

    if (matchScore > 0) {
      extractedSkills[skill.name] = matchScore
    }
  }

  return extractedSkills
}

function determineFinalStatus(validationResult: ValidationResult, provider: any): string {
  const { confidence } = validationResult
  const trustScore = provider.trust_score || 80

  // Adjust confidence based on provider trust score
  const adjustedConfidence = (confidence * trustScore) / 100

  if (adjustedConfidence >= 80) {
    return 'verified'
  } else if (adjustedConfidence >= 50) {
    return 'pending' // Requires manual review
  } else {
    return 'rejected'
  }
}

async function validateCareerBridge(supabase: any, certificateId: string, certificateUrl?: string): Promise<ValidationResult> {
  if (!certificateId) {
    return {
      isValid: false,
      confidence: 0,
      method: 'CareerBridge_api',
      extractedSkills: {},
      validationDetails: { error: 'Missing certificate ID' }
    }
  }

  // Determine if it represents the expected URL format
  if (certificateUrl && !certificateUrl.includes('career-bridge-app.vercel.app/verify/')) {
    // Only warn if they provided a URL that points elsewhere
    console.warn('CareerBridge URL is unusual:', certificateUrl);
  }

  try {
    const { data, error } = await supabase
      .from('student_course_certificates')
      .select('id, course_id, is_verified, certificate_number, student_name')
      .eq('certificate_number', certificateId)
      .single()

    if (error || !data) {
      return {
        isValid: false,
        confidence: 0,
        method: 'CareerBridge_api',
        extractedSkills: {},
        validationDetails: { error: 'Certificate ID not found in database', db_error: error?.message }
      }
    }

    // Must be marked as verified internally
    if (!data.is_verified) {
      return {
        isValid: false,
        confidence: 30, // Found but not verified internally
        method: 'CareerBridge_api',
        extractedSkills: {},
        validationDetails: { error: 'Certificate exists but is not completely internally verified' }
      }
    }

    return {
      isValid: true,
      confidence: 100, // We have 100% confidence in our own certificates
      method: 'CareerBridge_api',
      extractedSkills: {},
      validationDetails: {
        message: 'Successfully verified against internal database',
        course_id: data.course_id,
        student_name: data.student_name
      }
    }
  } catch (error: any) {
    console.error('CareerBridge validation failed:', error);
    return {
      isValid: false,
      confidence: 0,
      method: 'CareerBridge_api',
      extractedSkills: {},
      validationDetails: { error: error.message }
    }
  }
}